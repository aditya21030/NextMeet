import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String? id;
  final String imageUrl;
  final String caption; // Legacy field
  final String? partner1Caption; // Person 1's perspective
  final String? partner2Caption; // Person 2's perspective
  final DateTime date;
  final String location;
  final String? moodEmoji;
  final bool isStory; // New field for manual story selection
  final double? lat;
  final double? lng;

  MemoryModel({
    this.id,
    required this.imageUrl,
    this.caption = '',
    this.partner1Caption,
    this.partner2Caption,
    required this.date,
    required this.location,
    this.moodEmoji,
    this.isStory = false,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'caption': caption,
      'partner1Caption': partner1Caption,
      'partner2Caption': partner2Caption,
      'date': Timestamp.fromDate(date),
      'location': location,
      'moodEmoji': moodEmoji,
      'isStory': isStory,
      'lat': lat,
      'lng': lng,
    };
  }

  factory MemoryModel.fromFirestore(Map<String, dynamic> map, {String? id}) {
    return MemoryModel(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      partner1Caption: map['partner1Caption'],
      partner2Caption: map['partner2Caption'],
      date: (map['date'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      moodEmoji: map['moodEmoji'],
      isStory: map['isStory'] ?? false,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  MemoryModel copyWith({
    String? id,
    String? imageUrl,
    String? caption,
    String? partner1Caption,
    String? partner2Caption,
    DateTime? date,
    String? location,
    String? moodEmoji,
    bool? isStory,
    double? lat,
    double? lng,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      partner1Caption: partner1Caption ?? this.partner1Caption,
      partner2Caption: partner2Caption ?? this.partner2Caption,
      date: date ?? this.date,
      location: location ?? this.location,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      isStory: isStory ?? this.isStory,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}
