class AssignmentSubmission {
  final String studentId;
  final String fileUrl;
  final String fileName;
  final String studentName;
  final String? storagePath;
  final DateTime submittedAt;
  final double? grade;
  final String? feedback;

  AssignmentSubmission({
    required this.studentId,
    required this.studentName,
    required this.fileUrl,
    required this.fileName,
    required this.submittedAt,
    this.storagePath,
    this.grade,
    this.feedback,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? map['name'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'] as String)
          : map['uploadedAt'] != null
              ? DateTime.parse(map['uploadedAt'] as String)
              : DateTime.now(),
      grade: map['grade'] != null ? (map['grade'] as num).toDouble() : null,
      feedback: map['feedback'] as String?,
      storagePath: map['storagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'storagePath': storagePath,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'submittedAt': submittedAt.toIso8601String(),
      'grade': grade,
      'feedback': feedback,
    };
  }
}

class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final DateTime dueDate;
  final DateTime createdAt;
  final String createdBy;
  final List<AssignmentSubmission> submissions;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.dueDate,
    required this.createdAt,
    required this.createdBy,
    this.submissions = const [],
  });

  factory Assignment.fromMap(Map<String, dynamic> map, String id) {
    final subs = <AssignmentSubmission>[];
    // support both list and map storage for submissions
    if (map['submissions'] is List) {
      for (final s in (map['submissions'] as List)) {
        if (s is Map<String, dynamic>) {
          subs.add(AssignmentSubmission.fromMap(s));
        }
      }
    } else if (map['submissions'] is Map) {
      final m = Map<String, dynamic>.from(map['submissions'] as Map);
      for (final entry in m.entries) {
        final val = Map<String, dynamic>.from(entry.value as Map);
        // ensure studentId is present
        if (!val.containsKey('studentId')) val['studentId'] = entry.key;
        subs.add(AssignmentSubmission.fromMap(val));
      }
    }
    return Assignment(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      submissions: subs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'submissions': submissions.map((s) => s.toMap()).toList(),
    };
  }
}
