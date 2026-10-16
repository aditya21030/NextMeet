import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventModel {
  final String id;
  final String title;
  final DateTime date;
  final String type; // 'Date', 'Travel', 'Reunion', 'Special'
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  CalendarEventModel({
    required this.id,
    required this.title,
    required this.date,
    this.type = 'Date',
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'type': type,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }

  factory CalendarEventModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CalendarEventModel(
      id: id ?? map['id']?.toString() ?? '',
      title: map['title'] ?? map['name'] ?? '',
      date: _parseDate(map['date'] ?? map['eventDate']),
      type: map['type'] ?? 'Date',
      notes: map['notes']?.toString(),
      createdBy: map['createdBy']?.toString(),
      createdAt: map['createdAt'] != null ? _parseDate(map['createdAt']) : null,
    );
  }

  CalendarEventModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? type,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
