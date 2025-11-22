import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/material_model.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import 'quiz_take_screen.dart';
import '../../services/storage_service.dart';
import '../../utils/file_handler.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Tài liệu'), Tab(text: 'Bài tập'), Tab(text: 'Quiz')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _materialsTab(course),
          _assignmentsTab(course),
          _quizzesTab(course),
        ],
      ),
    );
  }

  Widget _materialsTab(Course course) {
    return StreamBuilder<List<CourseMaterial>>(
      stream: _firestoreService.getCourseMaterialsStream(course.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final materials = snapshot.data!;
        if (materials.isEmpty) return const Center(child: Text('Chưa có tài liệu'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final m = materials[index];
            return Card(
              child: ListTile(
                title: Text(m.title),
                subtitle: Text(m.fileName),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    // open file url (for web this opens new tab automatically)
                    // For now we simply launch URL using Uri
                    // In app we recommend using url_launcher
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Link tài liệu'),
                        content: SelectableText(m.fileUrl),
                        actions: [
                              // Safe: dialog button uses builder context synchronously when pressed.
                              // ignore: use_build_context_synchronously
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
                            ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _assignmentsTab(Course course) {
    return StreamBuilder<List<Assignment>>(
      stream: _firestoreService.getCourseAssignmentsStream(course.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final assignments = snapshot.data!;
        if (assignments.isEmpty) return const Center(child: Text('Chưa có bài tập'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            return Card(
              child: ListTile(
                title: Text(a.title),
                subtitle: Text('Hạn nộp: ${a.dueDate.toLocal()}'),
                trailing: ElevatedButton(
                  child: const Text('Nộp bài'),
                  onPressed: () => _submitAssignment(a),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitAssignment(Assignment assignment) async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để nộp bài')));
      return;
    }

    // Check existing submission
    final existingAssignment = await _firestoreService.getAssignment(widget.course.id, assignment.id);
    AssignmentSubmission? existingSubmission;
    if (existingAssignment != null) {
      for (final s in existingAssignment.submissions) {
        if (s.studentId == user.uid) {
          existingSubmission = s;
          break;
        }
      }
    }

    if (existingSubmission != null) {
      if (!mounted) return;
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bạn đã nộp trước đó'),
          content: const Text('Bạn đã nộp bài trước đó. Bạn có muốn ghi đè (thay thế) nộp bài trước?'),
          actions: [
            // Safe: dialog builder context is used synchronously when the button is pressed.
            // ignore: use_build_context_synchronously
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            // ignore: use_build_context_synchronously
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ghi đè')),
          ],
        ),
      );
      if (replace != true) return;
    }

    // Pick file
    final file = await FileHandler.pickFile(
      dialogTitle: 'Chọn file nộp bài (.zip/.rar/.7z)',
      fileType: FileType.custom,
      allowedExtensions: ['zip', 'rar', '7z'],
    );

    if (file == null) return; // user canceled

    // Validate extension
    final fileName = file.path.split(Platform.pathSeparator).last;
    if (!FileHandler.isValidAssignmentFile(fileName)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Định dạng file không hợp lệ. Chỉ chấp nhận .zip, .rar, .7z')));
      return;
    }

    // Validate size (limit 50MB)
    if (!FileHandler.isFileSizeValid(file, 50)) {
      final sizeMb = FileHandler.getFileSizeInMB(file).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File quá lớn ($sizeMb MB). Vui lòng chọn file ≤ 50MB')));
      return;
    }

    double progress = 0.0;
    void Function(void Function())? dialogSetState;

    // Show uploading dialog with progress
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setStateSB) {
        dialogSetState = setStateSB;
        return AlertDialog(
          title: const Text('Đang tải lên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 12),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        );
      }),
    );

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = fileName.split('.').last;
      final storagePath = 'submissions/${widget.course.id}/${assignment.id}/${user.uid}_$timestamp.$ext';

      final downloadUrl = await _storageService.uploadFile(storagePath, file, onProgress: (p) {
        progress = p;
        if (dialogSetState != null) dialogSetState!(() {});
      });

      // get student name from users collection (if present)
      final userData = await _authService.getUserData(user.uid);
      final studentName = userData?['fullName'] ?? user.email ?? 'Student';

      final submission = {
        'studentId': user.uid,
        'studentName': studentName,
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'storagePath': storagePath,
        'submittedAt': DateTime.now().toIso8601String(),
        'grade': null,
      };

      await _firestoreService.submitAssignment(widget.course.id, assignment.id, submission);

      // After successful submit, delete previous storage file if it exists and is different
      try {
        if (existingSubmission != null && existingSubmission.storagePath != null && existingSubmission.storagePath!.isNotEmpty && existingSubmission.storagePath != storagePath) {
          await _storageService.deleteFile(existingSubmission.storagePath!);
        }
      } catch (e) {
        // ignore delete errors but inform via console
        debugPrint('Warning: failed to delete old submission file: $e');
      }

      if (mounted) {
        Navigator.pop(context); // close uploading dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nộp bài thành công')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close uploading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi nộp bài: $e')));
      }
    }
  }

  Widget _quizzesTab(Course course) {
    return StreamBuilder<List<Quiz>>(
      stream: _firestoreService.getCourseQuizzesStream(course.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final quizzes = snapshot.data!;
        if (quizzes.isEmpty) return const Center(child: Text('Chưa có quiz'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final q = quizzes[index];
            return Card(
              child: ListTile(
                title: Text(q.title),
                subtitle: Text('Câu hỏi: ${q.questions.length} - Điểm: ${q.getTotalPoints()}'),
                trailing: ElevatedButton(
                  child: const Text('Làm bài'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuizTakeScreen(courseId: course.id, quiz: q)),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
