import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationResult {
  final String name;
  final double lat;
  final double lng;

  LocationResult({required this.name, required this.lat, required this.lng});

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      name: json['display_name'] ?? '',
      lat: double.parse(json['lat']),
      lng: double.parse(json['lon']),
    );
  }
}

class LocationSearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<LocationResult>> searchCities(String query) => search(query);

  Future<List<LocationResult>> search(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryEncoded = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$queryEncoded&format=json&limit=10&addressdetails=1'),
        headers: {
          'User-Agent': 'NextMeetApp/1.0', 
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.statusCode == 200 ? response.body : '[]');
        return data.map((json) => LocationResult.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
