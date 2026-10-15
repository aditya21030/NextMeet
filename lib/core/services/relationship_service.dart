import 'package:shared_preferences/shared_preferences.dart';
import '../models/relationship_model.dart';

class RelationshipService {
  static const String _storageKey = 'relationship_data';

  Future<void> saveRelationship(RelationshipModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, data.toJson());
  }

  Future<RelationshipModel> getRelationship() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_storageKey);
    if (json == null) {
      // Return default data
      return RelationshipModel(
        userName1: 'You',
        userName2: 'Partner',
        anniversaryDate: DateTime.now().subtract(const Duration(days: 420)),
        nextMeetingDate: DateTime.now().add(const Duration(days: 15)),
        distanceKm: 0,
        userLocation1: 'Origin',
        userLocation2: 'Destination',
        userMood1: 'Waiting... ⏳',
        lastMeetingDate: DateTime.now().subtract(const Duration(days: 72)),
        loveQuote: 'Your journey starts here ❤️',
      );
    }
    return RelationshipModel.fromJson(json);
  }
}
