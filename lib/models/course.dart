import 'package:flutter/material.dart';

class Course {
  final String id;
  final String name;
  final String instructorId; // UID của instructor
  final String instructorName; // Tên instructor
  final String description;
  final String colorHex;
  final List<String> studentIds; // Danh sách UID của students
  final DateTime createdAt;

  Course({
    required this.id,
    required this.name,
    required this.instructorId,
    required this.instructorName,
    required this.description,
    required this.colorHex,
    this.studentIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Course to Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'description': description,
      'colorHex': colorHex,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert Map từ Firestore thành Course object
  factory Course.fromMap(Map<String, dynamic> map, String docId) {
    return Course(
      id: docId,
      name: map['name'] ?? 'Unknown',
      instructorId: map['instructorId'] ?? '',
      instructorName: map['instructorName'] ?? 'Unknown',
      description: map['description'] ?? '',
      colorHex: map['colorHex'] ?? '#2196F3', // Default blue
      studentIds: List<String>.from(map['studentIds'] ?? []),
      createdAt: map['createdAt'] != null 
        ? DateTime.parse(map['createdAt'] as String)
        : DateTime.now(),
    );
  }

  // Chuyển hex color string thành Color object
  Color getColor() {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue; // Fallback
    }
  }
}
