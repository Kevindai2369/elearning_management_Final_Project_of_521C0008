# Implementation Guide - Chi Tiết Phát Triển Các Tính Năng

## Mục Đích
Hướng dẫn chi tiết cách thêm các tính năng cho hai vai trò Student và Instructor.

---

## Phần 1: Tính Năng cho STUDENT (Học sinh)

### 1.1 Browse & Enroll Courses (Duyệt & Đăng Ký Khóa Học)

#### Yêu Cầu
- Student xem tất cả khóa học
- Chọn khóa học để xem chi tiết
- Bấm "Đăng Ký" để enroll

#### Implementation Steps

**Step 1: Tạo BrowseCoursesScreen**

```dart
// lib/screens/student/browse_courses_screen.dart

class BrowseCoursesScreen extends StatefulWidget {
  const BrowseCoursesScreen({super.key});

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt Khóa Học'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khóa học...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Course list
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: _firestoreService.getAllCoursesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var courses = snapshot.data ?? [];
                
                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  courses = courses.where((course) {
                    return course.name.toLowerCase().contains(_searchQuery) ||
                        course.instructorName.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (courses.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy khóa học'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return _buildCourseCard(context, course);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final userId = AuthService().currentUser?.uid ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: course.getColor(), width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Giảng viên: ${course.instructorName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Học sinh: ${course.studentIds.length}'),
                ElevatedButton(
                  onPressed: () {
                    // Check if already enrolled
                    if (course.studentIds.contains(userId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn đã đăng ký khóa học này'),
                        ),
                      );
                    } else {
                      _enrollCourse(course.id, userId);
                    }
                  },
                  child: course.studentIds.contains(userId)
                      ? const Text('Đã Đăng Ký')
                      : const Text('Đăng Ký'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _enrollCourse(String courseId, String studentId) async {
    try {
      await _firestoreService.enrollStudentInCourse(courseId, studentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
```

**Step 2: Thêm navigation từ StudentDashboard**

```dart
// lib/main.dart - Update StudentDashboard

FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BrowseCoursesScreen(),
      ),
    );
  },
  child: const Icon(Icons.add),
),
```

---

### 1.2 View Course Materials (Xem Tài Liệu Khóa Học)

#### Yêu Cầu
- Student xem danh sách tài liệu (PDF, DOC)
- Tải file về máy

#### Firestore Structure

```
courses/{courseId}/materials/{materialId}
├── title: string
├── description: string
├── fileUrl: string (Firebase Storage URL)
├── fileName: string
├── fileSize: number
├── createdAt: timestamp
└── createdBy: string (instructor UID)
```

#### Models

```dart
// lib/models/material.dart

class Material {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize; // bytes
  final DateTime createdAt;
  final String createdBy;

  Material({
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

  factory Material.fromMap(Map<String, dynamic> map, String id) {
    return Material(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? 'file',
      fileSize: map['fileSize'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
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

  // Format file size
  String getFormattedSize() {
    const int mb = 1024 * 1024;
    if (fileSize >= mb) {
      return '${(fileSize / mb).toStringAsFixed(2)} MB';
    }
    return '${(fileSize / 1024).toStringAsFixed(2)} KB';
  }
}
```

#### FirestoreService Method

```dart
// lib/services/firestore_service.dart

/// Get materials for a course
Stream<List<Material>> getCourseMaterialsStream(String courseId) {
  return _db
      .collection('courses')
      .doc(courseId)
      .collection('materials')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Material.fromMap(doc.data(), doc.id))
        .toList();
  });
}

/// Add material (instructor only)
Future<String> addMaterial(String courseId, Material material) async {
  final ref = await _db
      .collection('courses')
      .doc(courseId)
      .collection('materials')
      .add(material.toMap());
  return ref.id;
}

/// Delete material
Future<void> deleteMaterial(String courseId, String materialId) async {
  await _db
      .collection('courses')
      .doc(courseId)
      .collection('materials')
      .doc(materialId)
      .delete();
}
```

---

### 1.3 Take Quizzes (Làm Bài Quiz)

#### Yêu Cầu
- Student xem danh sách quiz
- Làm bài quiz (multiple choice)
- Submit kết quả và xem điểm

#### Models

```dart
// lib/models/quiz.dart

class Question {
  final String id;
  final String question;
  final String type; // 'multiple_choice', 'true_false', 'short_answer'
  final List<String> options; // For multiple choice
  final int correctAnswer; // Index of correct answer
  final double points;

  Question({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.points = 1.0,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: map['type'] ?? 'multiple_choice',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      points: (map['points'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }
}

class Quiz {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<Question> questions;
  final int duration; // minutes
  final DateTime dueDate;
  final DateTime createdAt;
  final String createdBy;

  Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.questions,
    required this.duration,
    required this.dueDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory Quiz.fromMap(Map<String, dynamic> map, String id) {
    return Quiz(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      questions: List<Question>.from(
        (map['questions'] as List?)?.map((q) => Question.fromMap(q)) ?? [],
      ),
      duration: map['duration'] ?? 30,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'duration': duration,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  double getTotalPoints() {
    return questions.fold(0, (sum, q) => sum + q.points);
  }
}

class QuizResponse {
  final String id;
  final String quizId;
  final String studentId;
  final List<int> answers; // Selected answer indices
  final double score;
  final DateTime submittedAt;

  QuizResponse({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.score,
    required this.submittedAt,
  });

  factory QuizResponse.fromMap(Map<String, dynamic> map, String id) {
    return QuizResponse(
      id: id,
      quizId: map['quizId'] ?? '',
      studentId: map['studentId'] ?? '',
      answers: List<int>.from(map['answers'] ?? []),
      score: (map['score'] ?? 0).toDouble(),
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'answers': answers,
      'score': score,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
}
```

---

### 1.4 Submit Assignment (Nộp Bài Tập)

#### Yêu Cầu
- Xem danh sách assignment
- Tải file assignment
- Upload file đáp án (.rar, .zip) < 50MB

#### File Upload Handler

```dart
// lib/utils/file_handler.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileHandler {
  // Select file từ device
  static Future<File?> pickFile({
    String? dialogTitle,
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  // Validate file size (bytes)
  static bool isFileSizeValid(File file, int maxSizeInMB) {
    final fileSize = file.lengthSync();
    final maxSize = maxSizeInMB * 1024 * 1024;
    return fileSize <= maxSize;
  }

  // Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Validate assignment file type
  static bool isValidAssignmentFile(String fileName) {
    const validExtensions = ['.rar', '.zip', '.7z'];
    final extension = '.${fileName.split('.').last.toLowerCase()}';
    return validExtensions.contains(extension);
  }

  // Validate material file type
  static bool isValidMaterialFile(String fileName) {
    const validExtensions = ['.pdf', '.doc', '.docx', '.txt'];
    final extension = '.${fileName.split('.').last.toLowerCase()}';
    return validExtensions.contains(extension);
  }
}
```

---

## Phần 2: Tính Năng cho INSTRUCTOR (Giảng Viên)

### 2.1 Create Course (Tạo Khóa Học)

#### Implementation

```dart
// lib/screens/instructor/create_course_screen.dart

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  Color _selectedColor = Colors.blue;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.indigo,
    Colors.teal,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên khóa học')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mô tả khóa học')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid ?? '';
      final userData = await _authService.getUserData(userId);
      final instructorName = userData?['fullName'] ?? 'Unknown';

      // Convert color to hex
      final colorHex =
          '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

      final course = Course(
        id: '', // Will be generated by Firestore
        name: name,
        instructorId: userId,
        instructorName: instructorName,
        description: description,
        colorHex: colorHex,
        studentIds: [],
        createdAt: DateTime.now(),
      );

      await _firestoreService.addCourse(course);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khóa học đã được tạo!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Khóa Học'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên Khóa Học',
                hintText: 'Ví dụ: Lập Trình Dart',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô Tả Khóa Học',
                hintText: 'Mô tả chi tiết về khóa học...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Text(
              'Chọn Màu Sắc:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: _colorOptions.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.grey,
                        width: _selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createCourse,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo Khóa Học'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 2.2 Upload Course Materials (Upload Tài Liệu)

```dart
// lib/screens/instructor/upload_material_screen.dart

class UploadMaterialScreen extends StatefulWidget {
  final String courseId;

  const UploadMaterialScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _authService = AuthService();

  File? _selectedFile;
  bool _isLoading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await FileHandler.pickFile(
      dialogTitle: 'Chọn file tài liệu',
      fileType: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (file != null) {
      // Check file size (max 50MB)
      if (!FileHandler.isFileSizeValid(file, 50)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File vượt quá 50MB')),
          );
        }
        return;
      }

      setState(() => _selectedFile = file);
    }
  }

  Future<void> _uploadMaterial() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn file')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid ?? '';

      // Upload to Firebase Storage
      final fileName = _selectedFile!.path.split('/').last;
      final storagePath =
          'courses/$courseId/materials/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final fileUrl = await _storageService.uploadFile(storagePath, _selectedFile!);

      // Save metadata to Firestore
      final material = Material(
        id: '', // Will be generated
        courseId: courseId,
        title: _titleController.text,
        description: _descriptionController.text,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: _selectedFile!.lengthSync(),
        createdAt: DateTime.now(),
        createdBy: userId,
      );

      await _firestoreService.addMaterial(courseId, material);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Tài Liệu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu Đề',
                hintText: 'Ví dụ: Bài 1 - Giới Thiệu Dart',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô Tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // File picker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (_selectedFile == null) ...[
                    const Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Chưa chọn file'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Chọn File (PDF, DOC, DOCX)'),
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile!.path.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Size: ${FileHandler.getFileSizeInMB(_selectedFile!).toStringAsFixed(2)} MB',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text('Chọn File Khác'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadMaterial,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 2.3 Import Student List (CSV)

```dart
// lib/utils/csv_handler.dart

import 'dart:io';
import 'package:csv/csv.dart';

class CSVHandler {
  // Parse CSV file and return list of students (email, fullName)
  static Future<List<Map<String, String>>> parseStudentCSV(File file) async {
    try {
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      final students = <Map<String, String>>[];

      // Skip header row
      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length >= 2) {
          students.add({
            'email': row[0].toString().trim(),
            'fullName': row[1].toString().trim(),
          });
        }
      }

      return students;
    } catch (e) {
      print('Error parsing CSV: $e');
      rethrow;
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
```

---

## Phần 3: Thêm Dependencies

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.2.1
  cloud_firestore: ^6.1.0
  firebase_auth: ^6.1.2
  firebase_storage: ^13.0.4
  file_picker: ^5.3.3
  csv: ^5.0.0
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

```bash
flutter pub get
```

---

## Phần 4: Testing Checklist

### Student Features
- [ ] Browse available courses
- [ ] Enroll in a course
- [ ] View course materials
- [ ] Download material files
- [ ] Take a quiz
- [ ] Submit quiz answers
- [ ] View quiz results
- [ ] Submit assignment file
- [ ] View submitted assignment status

### Instructor Features
- [ ] Create a new course
- [ ] Upload course materials
- [ ] Upload assignment file
- [ ] Create quiz with questions
- [ ] Import student list from CSV
- [ ] View student submissions
- [ ] Grade submissions with feedback
- [ ] View course analytics

---

## Phần 5: Migration Guide

Nếu bạn đã có dữ liệu cũ, hãy làm theo bước này:

1. **Backup Firestore data**
   - Vào Firebase Console → Firestore → Export

2. **Update Firestore Rules** (để phù hợp với subcollections)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users
       match /users/{userId} {
         allow read, write: if request.auth.uid == userId;
       }

       // Courses
       match /courses/{courseId} {
         allow read: if true;
         allow write: if request.auth.uid == resource.data.instructorId;

         // Subcollections
         match /{subcollection=**} {
           allow read: if request.auth.uid in resource.parent.data.studentIds ||
                          request.auth.uid == resource.parent.data.instructorId;
           allow write: if request.auth.uid == resource.parent.data.instructorId;
         }
       }
     }
   }
   ```

3. **Run migration script** (nếu cần update old data structure)

---

**Last Updated:** 22/01/2025
