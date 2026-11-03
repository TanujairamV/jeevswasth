import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'registration_location.dart';

class RegistrationLocationException implements Exception {
  const RegistrationLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RegistrationLocationService {
  RegistrationLocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RegistrationLocation> detect() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const RegistrationLocationException('Turn on location services and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const RegistrationLocationException('Location permission was denied. You can continue without location.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const RegistrationLocationException('Location permission is permanently denied. Enable it in device settings or continue without location.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (position.latitude < -90 || position.latitude > 90 || position.longitude < -180 || position.longitude > 180) {
      throw const RegistrationLocationException('The device returned invalid coordinates.');
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
      });
      final response = await _client.get(uri, headers: kIsWeb ? null : const {'accept': 'application/json', 'user-agent': 'JEEVSWASTH/1.0'}).timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return RegistrationLocation(latitude: position.latitude, longitude: position.longitude);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final address = Map<String, dynamic>.from(body['address'] as Map? ?? const {});
      return RegistrationLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        state: _firstString(address, const ['state']),
        district: _firstString(address, const ['state_district', 'district', 'county']),
        locality: _firstString(address, const ['city', 'town', 'village', 'municipality', 'suburb']),
        postalCode: _firstString(address, const ['postcode']),
        formattedAddress: body['display_name'] as String?,
      );
    } catch (_) {
      return RegistrationLocation(latitude: position.latitude, longitude: position.longitude);
    }
  }

  String? _firstString(Map<String, dynamic> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
