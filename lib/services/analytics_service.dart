import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student Analytics
  Future<Map<String, dynamic>> getStudentAnalytics(String studentId) async {
    try {
      // Get all submissions
      final submissionsSnapshot = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .get();

      // Get all quiz attempts
      final quizAttemptsSnapshot = await _firestore
          .collection('quizAttempts')
          .where('studentId', isEqualTo: studentId)
          .get();

      // Calculate statistics
      int totalAssignments = submissionsSnapshot.docs.length;
      int gradedAssignments = submissionsSnapshot.docs
          .where((doc) => doc.data()['grade'] != null)
          .length;

      double totalAssignmentGrade = 0;
      int assignmentCount = 0;

      for (var doc in submissionsSnapshot.docs) {
        final grade = doc.data()['grade'];
        if (grade != null) {
          totalAssignmentGrade += (grade as num).toDouble();
          assignmentCount++;
        }
      }

      double avgAssignmentGrade =
          assignmentCount > 0 ? totalAssignmentGrade / assignmentCount : 0;

      int totalQuizzes = quizAttemptsSnapshot.docs.length;
      double totalQuizScore = 0;
      int quizCount = 0;

      for (var doc in quizAttemptsSnapshot.docs) {
        final score = doc.data()['score'];
        if (score != null) {
          totalQuizScore += (score as num).toDouble();
          quizCount++;
        }
      }

      double avgQuizScore = quizCount > 0 ? totalQuizScore / quizCount : 0;

      // Get enrolled courses
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      List<String> enrolledCourseIds = [];
      if (userDoc.exists && userDoc.data()?['enrolledCourses'] != null) {
        enrolledCourseIds =
            List<String>.from(userDoc.data()!['enrolledCourses']);
      }

      return {
        'totalAssignments': totalAssignments,
        'gradedAssignments': gradedAssignments,
        'avgAssignmentGrade': avgAssignmentGrade,
        'totalQuizzes': totalQuizzes,
        'avgQuizScore': avgQuizScore,
        'enrolledCoursesCount': enrolledCourseIds.length,
        'submissionsByGrade': _groupSubmissionsByGrade(submissionsSnapshot.docs),
        'quizScoresByQuiz': _groupQuizScores(quizAttemptsSnapshot.docs),
      };
    } catch (e) {
      print('Error getting student analytics: $e');
      return {};
    }
  }

  // Instructor/Course Analytics
  Future<Map<String, dynamic>> getCourseAnalytics(String courseId) async {
    try {
      // Get course details
      final courseDoc =
          await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return {};

      final courseData = courseDoc.data()!;
      List<String> studentIds = List<String>.from(courseData['studentIds'] ?? []);

      // Get all assignments for this course
      final assignmentsSnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Get all quizzes for this course
      final quizzesSnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Get all submissions for this course
      final submissionsSnapshot = await _firestore
          .collection('submissions')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Get all quiz attempts for this course
      final quizAttemptsSnapshot = await _firestore
          .collection('quizAttempts')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Calculate statistics
      int totalStudents = studentIds.length;
      int totalAssignments = assignmentsSnapshot.docs.length;
      int totalQuizzes = quizzesSnapshot.docs.length;
      int totalSubmissions = submissionsSnapshot.docs.length;
      int totalQuizAttempts = quizAttemptsSnapshot.docs.length;

      // Calculate average grades
      double totalGrade = 0;
      int gradedCount = 0;

      for (var doc in submissionsSnapshot.docs) {
        final grade = doc.data()['grade'];
        if (grade != null) {
          totalGrade += (grade as num).toDouble();
          gradedCount++;
        }
      }

      double avgGrade = gradedCount > 0 ? totalGrade / gradedCount : 0;

      // Calculate submission rate
      double submissionRate = totalAssignments > 0 && totalStudents > 0
          ? (totalSubmissions / (totalAssignments * totalStudents)) * 100
          : 0;

      // Calculate quiz completion rate
      double quizCompletionRate = totalQuizzes > 0 && totalStudents > 0
          ? (quizAttemptsSnapshot.docs
                      .map((doc) => doc.data()['studentId'])
                      .toSet()
                      .length /
                  totalStudents) *
              100
          : 0;

      return {
        'totalStudents': totalStudents,
        'totalAssignments': totalAssignments,
        'totalQuizzes': totalQuizzes,
        'totalSubmissions': totalSubmissions,
        'totalQuizAttempts': totalQuizAttempts,
        'avgGrade': avgGrade,
        'submissionRate': submissionRate,
        'quizCompletionRate': quizCompletionRate,
        'gradeDistribution': _calculateGradeDistribution(submissionsSnapshot.docs),
        'assignmentSubmissions':
            _groupSubmissionsByAssignment(submissionsSnapshot.docs),
        'quizScores': _groupQuizScoresByCourse(quizAttemptsSnapshot.docs),
      };
    } catch (e) {
      print('Error getting course analytics: $e');
      return {};
    }
  }

  // Helper: Group submissions by grade range
  Map<String, int> _groupSubmissionsByGrade(
      List<QueryDocumentSnapshot> submissions) {
    Map<String, int> distribution = {
      'A (90-100)': 0,
      'B (80-89)': 0,
      'C (70-79)': 0,
      'D (60-69)': 0,
      'F (<60)': 0,
    };

    for (var doc in submissions) {
      final data = doc.data() as Map<String, dynamic>?;
      final grade = data?['grade'];
      if (grade != null) {
        double g = (grade as num).toDouble();
        if (g >= 90) {
          distribution['A (90-100)'] = distribution['A (90-100)']! + 1;
        } else if (g >= 80) {
          distribution['B (80-89)'] = distribution['B (80-89)']! + 1;
        } else if (g >= 70) {
          distribution['C (70-79)'] = distribution['C (70-79)']! + 1;
        } else if (g >= 60) {
          distribution['D (60-69)'] = distribution['D (60-69)']! + 1;
        } else {
          distribution['F (<60)'] = distribution['F (<60)']! + 1;
        }
      }
    }

    return distribution;
  }

  // Helper: Calculate grade distribution
  Map<String, int> _calculateGradeDistribution(
      List<QueryDocumentSnapshot> submissions) {
    return _groupSubmissionsByGrade(submissions);
  }

  // Helper: Group submissions by assignment
  Map<String, double> _groupSubmissionsByAssignment(
      List<QueryDocumentSnapshot> submissions) {
    Map<String, List<double>> assignmentGrades = {};

    for (var doc in submissions) {
      final data = doc.data() as Map<String, dynamic>?;
      final assignmentId = data?['assignmentId'] as String?;
      final grade = data?['grade'];

      if (assignmentId != null && grade != null) {
        if (!assignmentGrades.containsKey(assignmentId)) {
          assignmentGrades[assignmentId] = [];
        }
        assignmentGrades[assignmentId]!.add((grade as num).toDouble());
      }
    }

    // Calculate average for each assignment
    Map<String, double> avgGrades = {};
    assignmentGrades.forEach((assignmentId, grades) {
      double sum = grades.reduce((a, b) => a + b);
      avgGrades[assignmentId] = sum / grades.length;
    });

    return avgGrades;
  }

  // Helper: Group quiz scores
  Map<String, double> _groupQuizScores(List<QueryDocumentSnapshot> attempts) {
    Map<String, List<double>> quizScores = {};

    for (var doc in attempts) {
      final data = doc.data() as Map<String, dynamic>?;
      final quizId = data?['quizId'] as String?;
      final score = data?['score'];

      if (quizId != null && score != null) {
        if (!quizScores.containsKey(quizId)) {
          quizScores[quizId] = [];
        }
        quizScores[quizId]!.add((score as num).toDouble());
      }
    }

    // Calculate average for each quiz
    Map<String, double> avgScores = {};
    quizScores.forEach((quizId, scores) {
      double sum = scores.reduce((a, b) => a + b);
      avgScores[quizId] = sum / scores.length;
    });

    return avgScores;
  }

  // Helper: Group quiz scores by course
  Map<String, double> _groupQuizScoresByCourse(
      List<QueryDocumentSnapshot> attempts) {
    return _groupQuizScores(attempts);
  }
}
