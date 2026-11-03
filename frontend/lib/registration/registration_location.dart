class RegistrationLocation {
  const RegistrationLocation({
    required this.latitude,
    required this.longitude,
    this.state,
    this.district,
    this.locality,
    this.postalCode,
    this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String? state;
  final String? district;
  final String? locality;
  final String? postalCode;
  final String? formattedAddress;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (state != null && state!.isNotEmpty) 'state': state,
        if (district != null && district!.isNotEmpty) 'district': district,
        if (locality != null && locality!.isNotEmpty) 'locality': locality,
        if (postalCode != null && postalCode!.isNotEmpty) 'postalCode': postalCode,
        if (formattedAddress != null && formattedAddress!.isNotEmpty) 'formattedAddress': formattedAddress,
      };
}
