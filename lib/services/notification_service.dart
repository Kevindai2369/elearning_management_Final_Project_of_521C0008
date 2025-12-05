import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications stream for a user
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? courseId,
    String? courseName,
    String? relatedId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        courseId: courseId,
        courseName: courseName,
        relatedId: relatedId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Notify students when assignment is created
  Future<void> notifyAssignmentCreated({
    required String courseId,
    required String courseName,
    required String assignmentTitle,
    required String assignmentId,
    required List<String> studentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (String studentId in studentIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        final notification = NotificationModel(
          id: notificationRef.id,
          userId: studentId,
          title: 'Bài Tập Mới',
          message: 'Bài tập "$assignmentTitle" đã được tạo trong khóa học $courseName',
          type: NotificationType.assignmentCreated,
          courseId: courseId,
          courseName: courseName,
          relatedId: assignmentId,
          createdAt: DateTime.now(),
        );

        batch.set(notificationRef, notification.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      print('Error notifying assignment created: $e');
    }
  }

  // Notify students when quiz is created
  Future<void> notifyQuizCreated({
    required String courseId,
    required String courseName,
    required String quizTitle,
    required String quizId,
    required List<String> studentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (String studentId in studentIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        final notification = NotificationModel(
          id: notificationRef.id,
          userId: studentId,
          title: 'Quiz Mới',
          message: 'Quiz "$quizTitle" đã được tạo trong khóa học $courseName',
          type: NotificationType.quizCreated,
          courseId: courseId,
          courseName: courseName,
          relatedId: quizId,
          createdAt: DateTime.now(),
        );

        batch.set(notificationRef, notification.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      print('Error notifying quiz created: $e');
    }
  }

  // Notify student when assignment is graded
  Future<void> notifyAssignmentGraded({
    required String studentId,
    required String courseId,
    required String courseName,
    required String assignmentTitle,
    required String assignmentId,
    required double grade,
  }) async {
    try {
      await createNotification(
        userId: studentId,
        title: 'Bài Tập Đã Được Chấm',
        message:
            'Bài tập "$assignmentTitle" đã được chấm điểm: $grade/100 trong khóa học $courseName',
        type: NotificationType.assignmentGraded,
        courseId: courseId,
        courseName: courseName,
        relatedId: assignmentId,
      );
    } catch (e) {
      print('Error notifying assignment graded: $e');
    }
  }

  // Notify student when enrolled in course
  Future<void> notifyCourseEnrolled({
    required String studentId,
    required String courseId,
    required String courseName,
  }) async {
    try {
      await createNotification(
        userId: studentId,
        title: 'Đăng Ký Khóa Học Thành Công',
        message: 'Bạn đã đăng ký thành công khóa học "$courseName"',
        type: NotificationType.courseEnrolled,
        courseId: courseId,
        courseName: courseName,
      );
    } catch (e) {
      print('Error notifying course enrolled: $e');
    }
  }

  // Notify when new comment
  Future<void> notifyNewComment({
    required String userId,
    required String courseId,
    required String courseName,
    required String commenterName,
  }) async {
    try {
      await createNotification(
        userId: userId,
        title: 'Bình Luận Mới',
        message: '$commenterName đã bình luận trong khóa học $courseName',
        type: NotificationType.comment,
        courseId: courseId,
        courseName: courseName,
      );
    } catch (e) {
      print('Error notifying new comment: $e');
    }
  }
}
