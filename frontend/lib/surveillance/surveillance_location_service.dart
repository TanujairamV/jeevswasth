import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SurveillanceLocationService {
  SurveillanceLocationService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  Future<List<SurveillanceLocationCluster>> fetchClusters({
    int minimumReports = 5,
    DateTime? since,
  }) async {
    final query = <String, String>{
      'minimumReports': minimumReports.toString(),
      if (since != null) 'since': since.toUtc().toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/reports/locations/clusters').replace(queryParameters: query);
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Location clusters unavailable (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final clusters = body['clusters'];
    if (clusters is! List) return const [];
    return clusters.whereType<Map<String, dynamic>>().map(SurveillanceLocationCluster.fromJson).toList();
  }

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('JEEVSWASTH_API_BASE_URL');
    const androidHost = String.fromEnvironment('JEEVSWASTH_ANDROID_API_HOST', defaultValue: '10.0.2.2');
    if (configured.isNotEmpty) return configured;
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://$androidHost:3000';
    return 'http://localhost:3000';
  }
}

class SurveillanceLocationCluster {
  const SurveillanceLocationCluster({
    required this.clusterId,
    required this.position,
    required this.reportCount,
    required this.affectedAnimals,
    required this.species,
    required this.firstReportTimestamp,
    required this.lastReportTimestamp,
    required this.minimumReports,
    this.riskLevel,
  });

  final String clusterId;
  final LatLng position;
  final int reportCount;
  final int affectedAnimals;
  final List<String> species;
  final DateTime firstReportTimestamp;
  final DateTime lastReportTimestamp;
  final int minimumReports;
  final String? riskLevel;

  factory SurveillanceLocationCluster.fromJson(Map<String, dynamic> json) {
    return SurveillanceLocationCluster(
      clusterId: json['clusterId'] as String,
      position: LatLng((json['latitude'] as num).toDouble(), (json['longitude'] as num).toDouble()),
      reportCount: (json['reportCount'] as num).toInt(),
      affectedAnimals: (json['affectedAnimals'] as num).toInt(),
      species: List<String>.from(json['species'] as List<dynamic>? ?? const []),
      firstReportTimestamp: DateTime.parse(json['firstReportTimestamp'] as String),
      lastReportTimestamp: DateTime.parse(json['lastReportTimestamp'] as String),
      minimumReports: ((json['privacy'] as Map<String, dynamic>?)?['minimumReports'] as num?)?.toInt() ?? 5,
      riskLevel: json['riskLevel'] as String?,
    );
  }
}
