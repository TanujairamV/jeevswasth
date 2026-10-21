import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/livestock_survey.dart';

class ReportsApiClient {
  ReportsApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ReportsApiConfig.baseUrl;
  final http.Client _client;
  final String baseUrl;

  Future<String> submit(LivestockSurvey survey) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/reports'),
      headers: {'content-type': 'application/json'},
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
      throw Exception(message);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final reportId = body['reportId'];
    if (reportId is! String || reportId.isEmpty) throw Exception('Report submission returned no report ID.');
    return reportId;
  }
}

class ReportsApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment(
    'JEEVSWASTH_API_BASE_URL',
  );
  static const _androidHost = String.fromEnvironment(
    'JEEVSWASTH_ANDROID_API_HOST',
    defaultValue: '10.0.2.2',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulators reach the host machine through 10.0.2.2. For a
      // physical device, pass the computer's LAN address instead.
      return 'http://$_androidHost:3000';
    }
    return 'http://localhost:3000';
  }
}
