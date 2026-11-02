import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/livestock_survey.dart';

class ReportsApiException implements Exception {
  const ReportsApiException(this.message, {this.kind = ReportsApiErrorKind.unknown, this.statusCode});
  final String message;
  final ReportsApiErrorKind kind;
  final int? statusCode;
  @override
  String toString() => message;
}

enum ReportsApiErrorKind { authentication, http, timeout, network, malformedResponse, unknown }

class BackendProfile {
  const BackendProfile({required this.roles, required this.pendingRoleRequests});
  final List<String> roles;
  final List<String> pendingRoleRequests;
  factory BackendProfile.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map);
    return BackendProfile(
      roles: List<String>.from(user['roles'] as List<dynamic>? ?? const []),
      pendingRoleRequests: List<String>.from(user['pendingRoleRequests'] as List<dynamic>? ?? const []),
    );
  }
}

class ApiReport {
  const ApiReport({required this.reportId, required this.survey});
  final String reportId;
  final LivestockSurvey survey;

  factory ApiReport.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    return ApiReport(
      reportId: json['reportId'] as String,
      survey: LivestockSurvey(
        id: json['clientReportId'] as String? ?? json['reportId'] as String,
        species: json['species'] as String,
        animalCount: (json['animalCount'] as num).toInt(),
        farmerName: json['farmerName'] as String? ?? '',
        farmerPhone: json['farmerPhone'] as String? ?? '',
        village: json['village'] as String,
        location: location is Map<String, dynamic> ? SurveyLocation.fromJson(location) : null,
        symptoms: List<String>.from(json['symptoms'] as List<dynamic>? ?? const []),
        clinicalSigns: List<String>.from(json['clinicalSigns'] as List<dynamic>? ?? const []),
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['reportTimestamp'] as String),
        syncStatus: SurveySyncStatus.synced,
      ),
    );
  }
}

class ReportsApiClient {
  ReportsApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ReportsApiConfig.baseUrl;
  final http.Client _client;
  final String baseUrl;

  Future<String> submit(LivestockSurvey survey) async {
    final response = await _request(
      () async => _client.post(
        Uri.parse('$baseUrl/api/v1/reports'),
        headers: await _headers(),
        body: jsonEncode({
        'clientReportId': survey.id,
        'species': survey.species,
        'animalCount': survey.animalCount,
        'village': survey.village,
        'symptoms': survey.symptoms,
        'reportTimestamp': survey.createdAt.toUtc().toIso8601String(),
        'farmerName': survey.farmerName,
        'farmerPhone': survey.farmerPhone,
        'clinicalSigns': survey.clinicalSigns,
        'notes': survey.notes,
        'location': survey.location?.toJson(),
        }),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Report submission failed (${response.statusCode}).';
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final missing = errorBody['missing'];
        if (missing is List && missing.isNotEmpty) {
          message = 'Validation failed. Missing or invalid: ${missing.join(', ')}.';
        } else if (errorBody['message'] is String) {
          message = errorBody['message'] as String;
        }
      } catch (_) {
        // Keep the status-based message when the server response is not JSON.
      }
      throw ReportsApiException(message, kind: ReportsApiErrorKind.http, statusCode: response.statusCode);
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final reportId = body['reportId'];
      if (reportId is! String || reportId.isEmpty) throw const FormatException();
      return reportId;
    } catch (_) {
      throw const ReportsApiException('The server returned an invalid submission response.', kind: ReportsApiErrorKind.malformedResponse);
    }
  }

  Future<List<ApiReport>> mine() async {
    final response = await _request(() async => _client.get(Uri.parse('$baseUrl/api/v1/reports/mine'), headers: await _headers()));
    if (response.statusCode != 200) throw ReportsApiException(_errorMessage(response, 'Could not load reports.'), kind: ReportsApiErrorKind.http, statusCode: response.statusCode);
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final reports = body['reports'];
      if (reports is! List) throw const FormatException();
      return reports.map((item) => ApiReport.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      throw const ReportsApiException('The server returned an invalid reports response.', kind: ReportsApiErrorKind.malformedResponse);
    }
  }

  Future<BackendProfile> verifySession({String? firebaseIdToken}) async {
    return profile(firebaseIdToken: firebaseIdToken);
  }

  Future<BackendProfile> profile({String? firebaseIdToken}) async {
    final response = await _request(() async => _client.get(Uri.parse('$baseUrl/api/v1/me'), headers: await _headers(firebaseIdToken: firebaseIdToken)));
    if (response.statusCode != 200) throw ReportsApiException(_errorMessage(response, 'Backend session verification failed.'), kind: ReportsApiErrorKind.http, statusCode: response.statusCode);
    try { return BackendProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>); } catch (_) { throw const ReportsApiException('The server returned an invalid profile response.', kind: ReportsApiErrorKind.malformedResponse); }
  }

  Future<String> requestRole(String role) async {
    final response = await _request(() async => _client.post(Uri.parse('$baseUrl/api/v1/me/role-requests'), headers: await _headers(), body: jsonEncode({'role': role})));
    if (response.statusCode != 200) throw ReportsApiException(_errorMessage(response, 'Could not save the role selection.'), kind: ReportsApiErrorKind.http, statusCode: response.statusCode);
    try { return (jsonDecode(response.body) as Map<String, dynamic>)['assignment'] as String; } catch (_) { throw const ReportsApiException('The server returned an invalid role response.', kind: ReportsApiErrorKind.malformedResponse); }
  }

  Future<Map<String, String>> _headers({String? firebaseIdToken}) async {
    final token = firebaseIdToken ?? await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) throw const ReportsApiException('Sign in before using reports.', kind: ReportsApiErrorKind.authentication);
    return {'content-type': 'application/json', 'accept': 'application/json', 'authorization': 'Bearer $token'};
  }

  Future<http.Response> _request(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 20));
    } on ReportsApiException {
      rethrow;
    } on TimeoutException {
      throw const ReportsApiException('The report service timed out. Check your connection and try again.', kind: ReportsApiErrorKind.timeout);
    } on http.ClientException {
      throw const ReportsApiException('Could not connect to the report service. Check your network connection and try again.', kind: ReportsApiErrorKind.network);
    } catch (_) {
      throw const ReportsApiException('The report request failed. Try again.', kind: ReportsApiErrorKind.unknown);
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['message'] is String) return body['message'] as String;
    } catch (_) {}
    final plainText = response.body.trim();
    if (plainText.isNotEmpty && plainText.length <= 240) return '$fallback: $plainText';
    return '$fallback (${response.statusCode}).';
  }
}

class ReportsApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment(
    'JEEVSWASTH_API_BASE_URL',
  );
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return 'https://jeevswasth-api.tanujairam.workers.dev';
  }
}
