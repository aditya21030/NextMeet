import 'dart:math';

class City {
  final String name;
  final double lat;
  final double lng;

  const City({required this.name, required this.lat, required this.lng});
}

class CityData {
  static const List<City> majorCities = [
    City(name: 'Mumbai', lat: 19.0760, lng: 72.8777),
    City(name: 'London', lat: 51.5074, lng: -0.1278),
    City(name: 'New York', lat: 40.7128, lng: -74.0060),
    City(name: 'Delhi', lat: 28.6139, lng: 77.2090),
    City(name: 'Tokyo', lat: 35.6895, lng: 139.6917),
    City(name: 'Dubai', lat: 25.2048, lng: 55.2708),
    City(name: 'Singapore', lat: 1.3521, lng: 103.8198),
    City(name: 'Paris', lat: 48.8566, lng: 2.3522),
    City(name: 'Sydney', lat: -33.8688, lng: 151.2093),
    City(name: 'Bangalore', lat: 12.9716, lng: 77.5946),
    City(name: 'Toronto', lat: 43.6532, lng: -79.3832),
    City(name: 'Berlin', lat: 52.5200, lng: 13.4050),
    City(name: 'Hyderabad', lat: 17.3850, lng: 78.4867),
    City(name: 'Los Angeles', lat: 34.0522, lng: -118.2437),
    City(name: 'San Francisco', lat: 37.7749, lng: -122.4194),
    City(name: 'Chennai', lat: 13.0827, lng: 80.2707),
    City(name: 'Moscow', lat: 55.7558, lng: 37.6173),
    City(name: 'Seoul', lat: 37.5665, lng: 126.9780),
    City(name: 'Kolkata', lat: 22.5726, lng: 88.3639),
    City(name: 'Amsterdam', lat: 52.3676, lng: 4.9041),
    City(name: 'Buenos Aires', lat: -34.6037, lng: -58.3816),
    City(name: 'Cairo', lat: 30.0444, lng: 31.2357),
    City(name: 'Cape Town', lat: -33.9249, lng: 18.4241),
    City(name: 'Istanbul', lat: 41.0082, lng: 28.9784),
    City(name: 'Mexico City', lat: 19.4326, lng: -99.1332),
    City(name: 'Rome', lat: 41.9028, lng: 12.4964),
    City(name: 'Bangkok', lat: 13.7563, lng: 100.5018),
    City(name: 'São Paulo', lat: -23.5505, lng: -46.6333),
    City(name: 'Jakarta', lat: -6.2088, lng: 106.8456),
    City(name: 'Riyadh', lat: 24.7136, lng: 46.6753),
  ];

  static const List<City> indianCities = majorCities; // Alias for backward compatibility

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
