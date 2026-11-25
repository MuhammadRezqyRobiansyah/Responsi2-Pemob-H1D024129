/// Represents a geographic city/location from Open-Meteo Geocoding API
/// or persisted in local storage (Favorites & Recent Searches).
class LocationModel {
  const LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.countryCode,
    this.admin1,
    this.timezone,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String countryCode;
  final String? admin1;
  final String? timezone;

  factory LocationModel.fromGeocodingJson(Map<String, dynamic> json) {
    final rawLat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final rawLon = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    final code = (json['country_code'] as String?)?.trim() ?? '';
    final countryName = (json['country'] as String?)?.trim() ?? code;

    return LocationModel(
      id: (json['id'] as num?)?.toInt() ??
          '${rawLat.toStringAsFixed(3)}_${rawLon.toStringAsFixed(3)}'.hashCode,
      name: (json['name'] as String?)?.trim() ?? 'Tidak diketahui',
      latitude: rawLat,
      longitude: rawLon,
      country: countryName.isEmpty ? 'Tidak diketahui' : countryName,
      countryCode: code.isEmpty ? '--' : code,
      admin1: (json['admin1'] as String?)?.trim(),
      timezone: (json['timezone'] as String?)?.trim(),
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Tidak diketahui',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      country: (json['country'] as String?) ?? 'Tidak diketahui',
      countryCode: (json['countryCode'] as String?) ?? '--',
      admin1: json['admin1'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'countryCode': countryCode,
      'admin1': admin1,
      'timezone': timezone,
    };
  }

  /// Stable coordinate-backed identifier so favorites match across reloads.
  String get locationKey =>
      '${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';

  /// Compact header format matching Screen 1: "Yogyakarta, ID".
  String get headerTitle =>
      countryCode != '--' ? '$name, $countryCode' : name;

  /// Full format matching Screen 4: "Yogyakarta, Indonesia".
  String get fullTitle =>
      country != 'Tidak diketahui' ? '$name, $country' : name;

  /// Subtitle format matching Screen 2 favorite cards.
  String get subtitleWithCoords =>
      '$country · ${latitude.toStringAsFixed(2)}°, ${longitude.toStringAsFixed(2)}°';

  /// Region subtitle for Geocoding search results.
  String get searchSubtitle {
    final parts = <String>[];
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      parts.add(admin1!);
    }
    if (country != 'Tidak diketahui') {
      parts.add(country);
    }
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationModel && locationKey == other.locationKey;

  @override
  int get hashCode => locationKey.hashCode;
}
