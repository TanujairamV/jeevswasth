import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AdminApiException implements Exception {
  const AdminApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class AdminOverview {
  const AdminOverview({required this.metrics, required this.roles, required this.userTrend, required this.reportTrend, required this.species, required this.regions, required this.recentActivity, required this.pendingPreview});
  final Map<String, int> metrics;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> userTrend;
  final List<Map<String, dynamic>> reportTrend;
  final List<Map<String, dynamic>> species;
  final List<Map<String, dynamic>> regions;
  final List<Map<String, dynamic>> recentActivity;
  final List<Map<String, dynamic>> pendingPreview;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;
    List<Map<String, dynamic>> list(String key) => (json[key] is List)
        ? (json[key] as List).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : const [];
    return AdminOverview(
      metrics: {
        'users': number('total_users'),
        'active': number('active_users'),
        'farmers': number('total_farmers'),
        'veterinarians': number('total_veterinarians'),
        'officers': number('total_surveillance_officers'),
        'pending': number('pending_applications'),
        'reports': number('total_reports'),
        'recentReports': number('recent_reports'),
      },
      roles: list('role_distribution'),
      userTrend: list('user_registration_trend'),
      reportTrend: list('report_trend'),
      species: list('reports_by_species'),
      regions: list('reports_by_region'),
      recentActivity: list('recent_activity'),
      pendingPreview: list('pending_preview'),
    );
  }
}

class AdminApplication {
  const AdminApplication({required this.id, required this.status, required this.submittedAt, required this.requestedRole, required this.applicant, this.rejectionReason});
  final String id;
  final String status;
  final DateTime submittedAt;
  final String requestedRole;
  final Map<String, dynamic> applicant;
  final String? rejectionReason;

  factory AdminApplication.fromJson(Map<String, dynamic> json) => AdminApplication(
        id: json['id'] as String,
        status: json['status'] as String? ?? 'pending',
        submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ?? DateTime.now(),
        requestedRole: json['requestedRole'] as String? ?? '',
        applicant: Map<String, dynamic>.from(json['applicant'] as Map? ?? const {}),
        rejectionReason: json['rejectionReason'] as String?,
      );
}

class AdminReport {
  const AdminReport({required this.id, required this.species, required this.animalCount, required this.village, required this.timestamp, this.farmerName, this.ownerName, this.ownerEmail, this.symptoms = const [], this.clinicalSigns = const [], this.latitude, this.longitude, this.notes});
  final String id;
  final String species;
  final int animalCount;
  final String village;
  final DateTime timestamp;
  final String? farmerName;
  final String? ownerName;
  final String? ownerEmail;
  final List<String> symptoms;
  final List<String> clinicalSigns;
  final double? latitude;
  final double? longitude;
  final String? notes;

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        id: json['report_id'] as String? ?? json['reportId'] as String? ?? '',
        species: json['species'] as String? ?? 'Unknown',
        animalCount: (json['animal_count'] as num? ?? json['animalCount'] as num? ?? 0).toInt(),
        village: json['village'] as String? ?? 'Unknown',
        timestamp: DateTime.tryParse((json['report_timestamp'] ?? json['reportTimestamp'] ?? '') as String) ?? DateTime.now(),
        farmerName: json['farmer_name'] as String? ?? json['farmerName'] as String?,
        ownerName: json['owner_display_name'] as String?,
        ownerEmail: json['owner_email'] as String?,
        symptoms: _strings(json['symptoms']),
        clinicalSigns: _strings(json['clinical_signs'] ?? json['clinicalSigns']),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}

List<String> _strings(dynamic value) => value is List ? value.whereType<String>().toList() : const [];

class AdminApiClient {
  AdminApiClient({http.Client? client, String? baseUrl}) : _client = client ?? http.Client(), baseUrl = baseUrl ?? _baseUrl;
  final http.Client _client;
  final String baseUrl;

  static const _configuredBaseUrl = String.fromEnvironment('JEEVSWASTH_API_BASE_URL');
  static String get _baseUrl => _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : 'https://jeevswasth-api.tanujairam.workers.dev';

  Future<AdminOverview> overview() async {
    final response = await _get('/admin/overview');
    return AdminOverview.fromJson(_body(response));
  }

  Future<AdminPage<AdminApplication>> applications({String search = '', String? role, int page = 1}) async {
    final json = await _getJson('/admin/applications', {'search': search, 'role': ?role, 'page': '$page'});
    return AdminPage.fromJson(json, AdminApplication.fromJson);
  }

  Future<AdminApplication> application(String id) async => AdminApplication.fromJson(_body(await _get('/admin/applications/$id'))['application'] as Map<String, dynamic>);

  Future<void> approveApplication(String id) async { await _post('/admin/applications/$id/approve'); }

  Future<void> rejectApplication(String id, String reason) async { await _post('/admin/applications/$id/reject', {'reason': reason}); }

  Future<AdminPage<Map<String, dynamic>>> users({String search = '', String? role, String? status, int page = 1}) async {
    final json = await _getJson('/admin/users', {'search': search, 'role': ?role, 'status': ?status, 'page': '$page'});
    return AdminPage.fromJson(json, (item) => Map<String, dynamic>.from(item));
  }

  Future<Map<String, dynamic>> user(String id) async => Map<String, dynamic>.from(_body(await _get('/admin/users/$id'))['user'] as Map);

  Future<void> setUserStatus(String id, bool active) async { await _patch('/admin/users/$id/status', {'active': active}); }

  Future<AdminPage<AdminReport>> reports({String search = '', String? species, String? region, int page = 1}) async {
    final json = await _getJson('/admin/reports', {'search': search, 'species': ?species, 'region': ?region, 'page': '$page'});
    return AdminPage.fromJson(json, AdminReport.fromJson);
  }

  Future<AdminReport> report(String id) async => AdminReport.fromJson(_body(await _get('/admin/reports/$id'))['report'] as Map<String, dynamic>);

  Future<AdminPage<Map<String, dynamic>>> auditLogs({String search = '', int page = 1}) async {
    final json = await _getJson('/admin/audit-logs', {'search': search, 'page': '$page'});
    return AdminPage.fromJson(json, (item) => Map<String, dynamic>.from(item));
  }

  Future<http.Response> _get(String path) async => _request(() async => _client.get(Uri.parse('$baseUrl/api/v1$path'), headers: await _headers()));

  Future<Map<String, dynamic>> _getJson(String path, Map<String, String> parameters) async {
    final query = parameters.entries.where((entry) => entry.value.isNotEmpty).map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}').join('&');
    return _body(await _get('$path${query.isEmpty ? '' : '?$query'}'));
  }

  Future<void> _post(String path, [Map<String, dynamic>? body]) async {
    final response = await _request(() async => _client.post(Uri.parse('$baseUrl/api/v1$path'), headers: await _headers(), body: body == null ? null : jsonEncode(body)));
    if (response.statusCode < 200 || response.statusCode >= 300) throw AdminApiException(_message(response), statusCode: response.statusCode);
  }

  Future<void> _patch(String path, Map<String, dynamic> body) async {
    final response = await _request(() async => _client.patch(Uri.parse('$baseUrl/api/v1$path'), headers: await _headers(), body: jsonEncode(body)));
    if (response.statusCode < 200 || response.statusCode >= 300) throw AdminApiException(_message(response), statusCode: response.statusCode);
  }

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) throw const AdminApiException('Sign in before opening the administrator console.');
    return {'content-type': 'application/json', 'accept': 'application/json', 'authorization': 'Bearer $token'};
  }

  Future<http.Response> _request(Future<http.Response> Function() operation) async {
    try { return await operation().timeout(const Duration(seconds: 20)); }
    on AdminApiException { rethrow; }
    on TimeoutException { throw const AdminApiException('The administrator service timed out.'); }
    on http.ClientException { throw const AdminApiException('Could not connect to the administrator service.'); }
    catch (_) { throw const AdminApiException('The administrator request failed.'); }
  }

  Map<String, dynamic> _body(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) throw AdminApiException(_message(response), statusCode: response.statusCode);
    try { return Map<String, dynamic>.from(jsonDecode(response.body) as Map); } catch (_) { throw const AdminApiException('The administrator service returned an invalid response.'); }
  }

  String _message(http.Response response) {
    try { final body = jsonDecode(response.body); if (body is Map && body['message'] is String) return body['message'] as String; } catch (_) {}
    return 'Administrator request failed (${response.statusCode}).';
  }
}

class AdminPage<T> {
  const AdminPage({required this.items, required this.page, required this.pageSize, required this.total, required this.totalPages});
  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  factory AdminPage.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) => AdminPage(
        items: (json['items'] as List? ?? const []).whereType<Map>().map((item) => parse(Map<String, dynamic>.from(item))).toList(),
        page: (json['page'] as num? ?? 1).toInt(),
        pageSize: (json['pageSize'] as num? ?? 20).toInt(),
        total: (json['total'] as num? ?? 0).toInt(),
        totalPages: (json['totalPages'] as num? ?? 1).toInt(),
      );
}
