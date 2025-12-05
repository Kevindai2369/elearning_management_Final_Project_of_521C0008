import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class TestDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final math.Random _random = math.Random();
  
  // Callback for logging
  Function(String)? onLog;

  void _log(String message) {
    if (onLog != null) {
      onLog!(message);
    } else {
      print(message);
    }
  }

  // Generate test data for analytics
  Future<void> generateTestData({
    required String courseId,
    required String instructorId,
    required List<String> studentIds,
  }) async {
    _log('🚀 Bắt đầu tạo dữ liệu test...');

    // 1. Create assignments
    _log('📝 Tạo assignments...');
    List<String> assignmentIds = [];
    for (int i = 1; i <= 3; i++) {
      final assignmentRef = await _firestore.collection('assignments').add({
        'courseId': courseId,
        'title': 'Bài Tập $i',
        'description': 'Mô tả bài tập $i',
        'dueDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 7 * i)),
        ),
        'createdAt': Timestamp.now(),
      });
      assignmentIds.add(assignmentRef.id);
      _log('  ✅ Tạo assignment: ${assignmentRef.id}');
    }

    // 2. Create quizzes
    _log('📋 Tạo quizzes...');
    List<String> quizIds = [];
    for (int i = 1; i <= 2; i++) {
      final quizRef = await _firestore.collection('quizzes').add({
        'courseId': courseId,
        'title': 'Quiz $i',
        'description': 'Kiểm tra kiến thức $i',
        'questions': [
          {
            'question': 'Câu hỏi 1',
            'options': ['A', 'B', 'C', 'D'],
            'correctAnswer': 0,
          },
          {
            'question': 'Câu hỏi 2',
            'options': ['A', 'B', 'C', 'D'],
            'correctAnswer': 1,
          },
          {
            'question': 'Câu hỏi 3',
            'options': ['A', 'B', 'C', 'D'],
            'correctAnswer': 2,
          },
          {
            'question': 'Câu hỏi 4',
            'options': ['A', 'B', 'C', 'D'],
            'correctAnswer': 3,
          },
          {
            'question': 'Câu hỏi 5',
            'options': ['A', 'B', 'C', 'D'],
            'correctAnswer': 0,
          },
        ],
        'createdAt': Timestamp.now(),
      });
      quizIds.add(quizRef.id);
      _log('  ✅ Tạo quiz: ${quizRef.id}');
    }

    // 3. Create submissions for each student
    _log('📤 Tạo submissions...');
    int submissionCount = 0;
    for (String studentId in studentIds) {
      for (String assignmentId in assignmentIds) {
        // 80% chance student submits
        if (_random.nextDouble() < 0.8) {
          final grade = _generateGrade();
          await _firestore.collection('submissions').add({
            'courseId': courseId,
            'assignmentId': assignmentId,
            'studentId': studentId,
            'submittedAt': Timestamp.now(),
            'grade': grade,
            'feedback': _getFeedback(grade),
            'status': 'graded',
          });
          submissionCount++;
        }
      }
    }
    _log('  ✅ Tạo $submissionCount submissions');

    // 4. Create quiz attempts for each student
    _log('🎯 Tạo quiz attempts...');
    int attemptCount = 0;
    for (String studentId in studentIds) {
      for (String quizId in quizIds) {
        // 90% chance student takes quiz
        if (_random.nextDouble() < 0.9) {
          final score = _generateQuizScore();
          await _firestore.collection('quizAttempts').add({
            'courseId': courseId,
            'quizId': quizId,
            'studentId': studentId,
            'score': score,
            'totalQuestions': 5,
            'correctAnswers': (score / 20).round(),
            'submittedAt': Timestamp.now(),
          });
          attemptCount++;
        }
      }
    }
    _log('  ✅ Tạo $attemptCount quiz attempts');

    _log('✨ Hoàn thành! Dữ liệu test đã được tạo.');
    _log('📊 Bây giờ bạn có thể xem analytics với dữ liệu thực tế!');
  }

  // Generate realistic grade (0-100)
  double _generateGrade() {
    // Generate grades with normal distribution
    // Most grades around 70-85
    final base = 75.0;
    final variance = 15.0;
    
    double grade;
    do {
      // Box-Muller transform for normal distribution
      final u1 = _random.nextDouble();
      final u2 = _random.nextDouble();
      final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
      grade = base + (z * variance);
    } while (grade < 0 || grade > 100);

    return double.parse(grade.toStringAsFixed(1));
  }

  // Generate quiz score (0-100)
  double _generateQuizScore() {
    // Quiz scores tend to be higher
    final base = 80.0;
    final variance = 12.0;
    
    double score;
    do {
      final u1 = _random.nextDouble();
      final u2 = _random.nextDouble();
      final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
      score = base + (z * variance);
    } while (score < 0 || score > 100);

    return double.parse(score.toStringAsFixed(1));
  }

  String _getFeedback(double grade) {
    if (grade >= 90) return 'Xuất sắc! Làm rất tốt!';
    if (grade >= 80) return 'Tốt! Tiếp tục phát huy!';
    if (grade >= 70) return 'Khá! Cần cố gắng thêm!';
    if (grade >= 60) return 'Trung bình. Cần ôn tập thêm!';
    return 'Yếu. Cần học lại!';
  }

  // Quick test: Generate data for current user's first course
  Future<void> quickTest(String userId) async {
    _log('🔍 Tìm khóa học của bạn...');
    
    // Get user's first course as instructor
    final coursesSnapshot = await _firestore
        .collection('courses')
        .where('instructorId', isEqualTo: userId)
        .limit(1)
        .get();

    if (coursesSnapshot.docs.isEmpty) {
      _log('❌ Không tìm thấy khóa học nào. Vui lòng tạo khóa học trước!');
      return;
    }

    final courseDoc = coursesSnapshot.docs.first;
    final courseData = courseDoc.data();
    final courseId = courseDoc.id;
    final courseName = courseData['name'] ?? 'Unknown';
    final studentIds = List<String>.from(courseData['studentIds'] ?? []);

    _log('📚 Tìm thấy khóa học: $courseName');
    _log('👥 Số học sinh: ${studentIds.length}');

    if (studentIds.isEmpty) {
      _log('⚠️  Khóa học chưa có học sinh. Thêm học sinh trước!');
      return;
    }

    await generateTestData(
      courseId: courseId,
      instructorId: userId,
      studentIds: studentIds,
    );
  }
}
