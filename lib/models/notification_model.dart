import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  assignmentCreated,
  quizCreated,
  assignmentGraded,
  quizGraded,
  courseEnrolled,
  comment,
  general,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? courseId;
  final String? courseName;
  final String? relatedId; // assignmentId, quizId, etc.
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.courseId,
    this.courseName,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  // From Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseType(data['type']),
      courseId: data['courseId'],
      courseName: data['courseName'],
      relatedId: data['relatedId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'courseId': courseId,
      'courseName': courseName,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Parse type from string
  static NotificationType _parseType(String? typeString) {
    if (typeString == null) return NotificationType.general;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => NotificationType.general,
      );
    } catch (e) {
      return NotificationType.general;
    }
  }

  // Copy with
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? courseId,
    String? courseName,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get icon based on type
  String getIcon() {
    switch (type) {
      case NotificationType.assignmentCreated:
        return '📝';
      case NotificationType.quizCreated:
        return '📋';
      case NotificationType.assignmentGraded:
        return '✅';
      case NotificationType.quizGraded:
        return '🎯';
      case NotificationType.courseEnrolled:
        return '🎓';
      case NotificationType.comment:
        return '💬';
      case NotificationType.general:
        return '🔔';
    }
  }
}
