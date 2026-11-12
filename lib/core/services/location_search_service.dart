import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final String name;
  final double lat;
  final double lng;

  LocationResult({required this.name, required this.lat, required this.lng});

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      name: json['display_name']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      lng: double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
    );
  }

  /// True when coordinates parsed cleanly and are not the unset (0, 0) sentinel.
  bool get hasValidCoordinates =>
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90.0 &&
      lat <= 90.0 &&
      lng >= -180.0 &&
      lng <= 180.0 &&
      !(lat == 0.0 && lng == 0.0);
}

class LocationSearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<LocationResult>> searchCities(String query) => search(query);

  Future<List<LocationResult>> search(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryEncoded = Uri.encodeComponent(query);
      final response = await http
          .get(
            Uri.parse('$_baseUrl?q=$queryEncoded&format=json&limit=10&addressdetails=1'),
            headers: {
              'User-Agent': 'NextMeetApp/1.0 (com.yousful.nextmeet)',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LocationResult.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Automatically detect user's current city using GPS
  static Future<String?> getCurrentCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 4),
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
      }
    } catch (_) {}
    return null;
  }

  /// Automatically detect user's current city and coordinates using GPS
  static Future<Map<String, dynamic>?> getCurrentLocationWithCoords() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      String cityName = 'Current Location';
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
          final country = place.country ?? '';
          cityName = city.isNotEmpty ? (country.isNotEmpty ? '$city, $country' : city) : (country.isNotEmpty ? country : 'Current Location');
        }
      } catch (_) {}

      return {
        'city': cityName,
        'lat': position.latitude,
        'lng': position.longitude,
      };
    } catch (_) {
      return null;
    }
  }
}
