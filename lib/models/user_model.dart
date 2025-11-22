enum UserRole { student, instructor }

extension UserRoleExtension on UserRole {
  String get label {
    return this == UserRole.student ? 'Học sinh' : 'Giảng viên';
  }

  String get value {
    return this == UserRole.student ? 'student' : 'instructor';
  }
}

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final String? avatarUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
  });

  /// Chuyển đổi từ Firestore document sang UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] == 'instructor' 
        ? UserRole.instructor 
        : UserRole.student,
      createdAt: map['createdAt'] != null 
        ? DateTime.parse(map['createdAt'] as String)
        : DateTime.now(),
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  /// Chuyển đổi UserModel sang Firestore document format
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role.value,
      'createdAt': createdAt.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }

  /// Copy with method để dễ update field
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, email: $email, role: ${role.label})';
}
