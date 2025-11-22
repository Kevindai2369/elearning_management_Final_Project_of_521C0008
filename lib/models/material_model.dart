class CourseMaterial {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize; // bytes
  final DateTime createdAt;
  final String createdBy; // instructor uid

  CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    required this.createdBy,
  });

  factory CourseMaterial.fromMap(Map<String, dynamic> map, String id) {
    return CourseMaterial(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? 'file',
      fileSize: (map['fileSize'] ?? 0) as int,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
