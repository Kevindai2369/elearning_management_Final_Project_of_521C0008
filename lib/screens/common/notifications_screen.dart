import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Configure timeago for Vietnamese
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(userId),
            tooltip: 'Đánh dấu tất cả đã đọc',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoading.shimmerList();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_none,
              title: 'Chưa có thông báo',
              subtitle: 'Bạn sẽ nhận được thông báo về bài tập, quiz và các hoạt động khác',
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thông báo')),
        );
      },
      child: Container(
        color: notification.isRead ? null : Colors.blue[50],
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getTypeColor(notification.type),
            child: Text(
              notification.getIcon(),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                timeago.format(notification.createdAt, locale: 'vi'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => _handleNotificationTap(notification),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.assignmentCreated:
        return Colors.orange[100]!;
      case NotificationType.quizCreated:
        return Colors.purple[100]!;
      case NotificationType.assignmentGraded:
        return Colors.green[100]!;
      case NotificationType.quizGraded:
        return Colors.teal[100]!;
      case NotificationType.courseEnrolled:
        return Colors.blue[100]!;
      case NotificationType.comment:
        return Colors.pink[100]!;
      case NotificationType.general:
        return Colors.grey[100]!;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Navigate based on type
    if (notification.courseId != null) {
      // You can navigate to course detail or specific screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mở ${notification.courseName ?? "khóa học"}'),
          duration: const Duration(seconds: 1),
        ),
      );
      // TODO: Add navigation to course/assignment/quiz
    }
  }

  void _markAllAsRead(String userId) {
    _notificationService.markAllAsRead(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu tất cả đã đọc')),
    );
  }
}
