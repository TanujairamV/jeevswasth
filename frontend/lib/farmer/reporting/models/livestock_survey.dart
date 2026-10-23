import 'dart:convert';

enum SurveySyncStatus { pending, synced, failed }

class LivestockSurvey {
  const LivestockSurvey({
    required this.id,
    required this.species,
    required this.animalCount,
    required this.farmerName,
    required this.farmerPhone,
    required this.village,
    required this.location,
    required this.symptoms,
    required this.clinicalSigns,
    required this.notes,
    required this.createdAt,
    required this.syncStatus,
  });

  final String id;
  final String species;
  final int animalCount;
  final String farmerName;
  final String farmerPhone;
  final String village;
  final SurveyLocation? location;
  final List<String> symptoms;
  final List<String> clinicalSigns;
  final String notes;
  final DateTime createdAt;
  final SurveySyncStatus syncStatus;

  LivestockSurvey copyWith({SurveySyncStatus? syncStatus}) => LivestockSurvey(
        id: id,
        species: species,
        animalCount: animalCount,
        farmerName: farmerName,
        farmerPhone: farmerPhone,
        village: village,
        location: location,
        symptoms: symptoms,
        clinicalSigns: clinicalSigns,
        notes: notes,
        createdAt: createdAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'species': species,
        'animalCount': animalCount,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'village': village,
        'location': location?.toJson(),
        'symptoms': symptoms,
        'clinicalSigns': clinicalSigns,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'syncStatus': syncStatus.name,
      };

  factory LivestockSurvey.fromJson(Map<String, dynamic> json) => LivestockSurvey(
        id: json['id'] as String,
        species: json['species'] as String,
        animalCount: json['animalCount'] as int,
        farmerName: json['farmerName'] as String,
        farmerPhone: json['farmerPhone'] as String? ?? '',
        village: json['village'] as String,
        location: json['location'] == null
            ? null
            : SurveyLocation.fromJson(json['location'] as Map<String, dynamic>),
        symptoms: List<String>.from(json['symptoms'] as List<dynamic>? ?? const []),
        clinicalSigns: List<String>.from(json['clinicalSigns'] as List<dynamic>? ?? const []),
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncStatus: SurveySyncStatus.values.firstWhere(
          (value) => value.name == json['syncStatus'],
          orElse: () => SurveySyncStatus.pending,
        ),
      );
}

class SurveyLocation {
  const SurveyLocation({required this.latitude, required this.longitude, this.address});
  final double latitude;
  final double longitude;
  final String? address;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory SurveyLocation.fromJson(Map<String, dynamic> json) => SurveyLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
      );
}

String encodeSurveys(List<LivestockSurvey> surveys) => jsonEncode(
      surveys.map((survey) => survey.toJson()).toList(),
    );

List<LivestockSurvey> decodeSurveys(String? value) {
  if (value == null || value.isEmpty) return const [];
  final decoded = jsonDecode(value) as List<dynamic>;
  return decoded
      .map((item) => LivestockSurvey.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}
