import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/comment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class CourseDiscussionScreen extends StatefulWidget {
  final Course course;

  const CourseDiscussionScreen({super.key, required this.course});

  @override
  State<CourseDiscussionScreen> createState() => _CourseDiscussionScreenState();
}

class _CourseDiscussionScreenState extends State<CourseDiscussionScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  final _replyControllers = <String, TextEditingController>{};
  String? _replyingToId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    // Configure timeago to Vietnamese
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userId = _authService.currentUser?.uid ?? '';
    final userData = await _authService.getUserData(userId);
    final userName = userData?['fullName'] ?? 'Unknown';
    final userRole = userData?['role'] ?? 'student';

    final comment = Comment(
      id: '',
      courseId: widget.course.id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      content: content,
      createdAt: DateTime.now(),
      replyToId: _replyingToId,
    );

    try {
      await _firestoreService.addComment(comment);
      _commentController.clear();
      setState(() {
        _replyingToId = null;
        _replyingToUserName = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng bình luận')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final userId = _authService.currentUser?.uid ?? '';
    final userData = await _authService.getUserData(userId);
    final userRole = userData?['role'] ?? 'student';

    // Only allow delete if user is owner or instructor
    if (comment.userId != userId && userRole != 'instructor') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền xóa bình luận này')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteComment(widget.course.id, comment.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bình luận')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thảo Luận'),
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _firestoreService.getCourseCommentsStream(widget.course.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final allComments = snapshot.data ?? [];
                // Filter top-level comments (not replies)
                final topLevelComments = allComments
                    .where((c) => c.replyToId == null)
                    .toList();

                if (topLevelComments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có bình luận nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hãy là người đầu tiên bình luận!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: topLevelComments.length,
                  itemBuilder: (context, index) {
                    final comment = topLevelComments[index];
                    return _buildCommentCard(comment, userId, allComments);
                  },
                );
              },
            ),
          ),

          // Reply indicator
          if (_replyingToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang trả lời $_replyingToUserName',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _replyingToId = null;
                        _replyingToUserName = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyingToId != null 
                          ? 'Viết câu trả lời...' 
                          : 'Viết bình luận...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _postComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment, String currentUserId, List<Comment> allComments) {
    final isInstructor = comment.userRole == 'instructor';
    final isOwner = comment.userId == currentUserId;
    final replies = allComments.where((c) => c.replyToId == comment.id).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isInstructor ? Colors.orange : Colors.blue,
                  child: Text(
                    comment.userName.isNotEmpty 
                        ? comment.userName[0].toUpperCase() 
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isInstructor) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Giảng viên',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        timeago.format(comment.createdAt, locale: 'vi'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner || isInstructor)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteComment(comment);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Comment content
            Text(
              comment.content,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                // Like button
                InkWell(
                  onTap: () {
                    _firestoreService.toggleCommentLike(
                      widget.course.id,
                      comment.id,
                      currentUserId,
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        comment.isLikedBy(currentUserId)
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 18,
                        color: comment.isLikedBy(currentUserId)
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      if (comment.likeCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likeCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Reply button
                InkWell(
                  onTap: () {
                    setState(() {
                      _replyingToId = comment.id;
                      _replyingToUserName = comment.userName;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trả lời',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Replies
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 2),
                  ),
                ),
                child: Column(
                  children: replies.map((reply) {
                    return _buildReplyCard(reply, currentUserId);
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(Comment reply, String currentUserId) {
    final isInstructor = reply.userRole == 'instructor';
    final isOwner = reply.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isInstructor ? Colors.orange : Colors.blue,
                child: Text(
                  reply.userName.isNotEmpty 
                      ? reply.userName[0].toUpperCase() 
                      : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reply.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isInstructor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'GV',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeago.format(reply.createdAt, locale: 'vi'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner || isInstructor)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteComment(reply),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.content,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    _firestoreService.toggleCommentLike(
                      widget.course.id,
                      reply.id,
                      currentUserId,
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        reply.isLikedBy(currentUserId)
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 16,
                        color: reply.isLikedBy(currentUserId)
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      if (reply.likeCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${reply.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
