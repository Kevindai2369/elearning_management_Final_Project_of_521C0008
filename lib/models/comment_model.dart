class Comment {
  final String id;
  final String courseId;
  final String userId;
  final String userName;
  final String userRole; // 'student' or 'instructor'
  final String content;
  final DateTime createdAt;
  final String? replyToId; // null if top-level comment, commentId if reply
  final List<String> likes; // List of userIds who liked

  Comment({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.content,
    required this.createdAt,
    this.replyToId,
    this.likes = const [],
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      courseId: map['courseId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      userRole: map['userRole'] ?? 'student',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      replyToId: map['replyToId'],
      likes: List<String>.from(map['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'replyToId': replyToId,
      'likes': likes,
    };
  }

  Comment copyWith({
    String? id,
    String? courseId,
    String? userId,
    String? userName,
    String? userRole,
    String? content,
    DateTime? createdAt,
    String? replyToId,
    List<String>? likes,
  }) {
    return Comment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replyToId: replyToId ?? this.replyToId,
      likes: likes ?? this.likes,
    );
  }

  bool isReply() => replyToId != null;
  
  bool isLikedBy(String userId) => likes.contains(userId);
  
  int get likeCount => likes.length;
}
