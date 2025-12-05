import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_snackbar.dart';

class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() =>
      _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _sendTestNotifications() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get first course
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('instructorId', isEqualTo: userId)
          .limit(1)
          .get();

      if (coursesSnapshot.docs.isEmpty) {
        throw Exception('Không tìm thấy khóa học');
      }

      final courseDoc = coursesSnapshot.docs.first;
      final courseData = courseDoc.data();
      final courseId = courseDoc.id;
      final courseName = courseData['name'] ?? 'Unknown';
      final studentIds = List<String>.from(courseData['studentIds'] ?? []);

      if (studentIds.isEmpty) {
        throw Exception('Khóa học chưa có học sinh');
      }

      // Send different types of notifications
      await _notificationService.notifyAssignmentCreated(
        courseId: courseId,
        courseName: courseName,
        assignmentTitle: 'Bài Tập Test',
        assignmentId: 'test-assignment-id',
        studentIds: studentIds,
      );

      await _notificationService.notifyQuizCreated(
        courseId: courseId,
        courseName: courseName,
        quizTitle: 'Quiz Test',
        quizId: 'test-quiz-id',
        studentIds: studentIds,
      );

      // Send to first student
      if (studentIds.isNotEmpty) {
        await _notificationService.notifyAssignmentGraded(
          studentId: studentIds.first,
          courseId: courseId,
          courseName: courseName,
          assignmentTitle: 'Bài Tập Test',
          assignmentId: 'test-assignment-id',
          grade: 85.5,
        );

        await _notificationService.notifyCourseEnrolled(
          studentId: studentIds.first,
          courseId: courseId,
          courseName: courseName,
        );
      }

      if (mounted) {
        AppSnackbar.success(
          context,
          'Đã gửi ${studentIds.length * 2 + 2} thông báo test!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Lỗi: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Test Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tool này sẽ gửi thông báo test đến tất cả học sinh trong khóa học đầu tiên của bạn:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('📝 Thông báo bài tập mới'),
                    _buildInfoItem('📋 Thông báo quiz mới'),
                    _buildInfoItem('✅ Thông báo đã chấm điểm'),
                    _buildInfoItem('🎓 Thông báo đăng ký khóa học'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Lưu ý: Khóa học phải có học sinh!',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestNotifications,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Đang gửi...' : 'Gửi Thông Báo Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cách kiểm tra:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Gửi thông báo test'),
                    Text('2. Xem icon 🔔 trên AppBar (có badge đỏ)'),
                    Text('3. Click vào icon để xem danh sách thông báo'),
                    Text('4. Đăng nhập student để xem thông báo của họ'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
