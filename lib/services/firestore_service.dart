import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningfinal/models/course.dart';
import 'package:elearningfinal/models/material_model.dart';
import 'package:elearningfinal/models/assignment_model.dart';
import 'package:elearningfinal/models/quiz_model.dart';
import 'package:elearningfinal/models/comment_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Read a document once
  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
      String collection, String docId) async {
    return await _db.collection(collection).doc(docId).get();
  }

  // Stream a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
      String collection) {
    return _db.collection(collection).snapshots();
  }

  // Stream a single user document (for real-time profile updates)
  Stream<Map<String, dynamic>?> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Add cache-busting timestamp to avatar URL if it exists
        if (data['avatarUrl'] != null && (data['avatarUrl'] as String).isNotEmpty) {
          final avatarUrl = data['avatarUrl'] as String;
          // Add timestamp as query parameter to bust cache
          // Use & if URL already has query params, otherwise use ?
          final separator = avatarUrl.contains('?') ? '&' : '?';
          data['avatarUrl'] = '$avatarUrl${separator}v=${DateTime.now().millisecondsSinceEpoch}';
        }
        return data;
      }
      return null;
    });
  }

  // Create or update a document
  Future<void> setDoc(String collection, String docId, Map<String, dynamic> data,
      {bool merge = false}) async {
    await _db.collection(collection).doc(docId).set(data, SetOptions(merge: merge));
  }

  // Add a new document with generated id
  Future<DocumentReference<Map<String, dynamic>>> addDoc(
      String collection, Map<String, dynamic> data) async {
    return await _db.collection(collection).add(data);
  }

  // --- Courses Collection Helpers ---
  
  /// Lấy stream danh sách khóa học từ Firestore
  Stream<List<Course>> getCoursesStream() {
    return _db.collection('courses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Lấy một khóa học cụ thể
  Future<Course?> getCourse(String courseId) async {
    final doc = await _db.collection('courses').doc(courseId).get();
    if (doc.exists && doc.data() != null) {
      return Course.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Tạo khóa học mới
  Future<String> addCourse(Course course) async {
    final ref = await _db.collection('courses').add(course.toMap());
    return ref.id;
  }

  /// Cập nhật khóa học
  Future<void> updateCourse(String courseId, dynamic courseData) async {
    if (courseData is Course) {
      await _db.collection('courses').doc(courseId).set(courseData.toMap());
    } else if (courseData is Map<String, dynamic>) {
      await _db.collection('courses').doc(courseId).update(courseData);
    } else {
      throw ArgumentError('courseData must be either Course or Map<String, dynamic>');
    }
  }

  /// Xoá khóa học
  Future<void> deleteCourse(String courseId) async {
    await _db.collection('courses').doc(courseId).delete();
  }

  /// Lấy stream khóa học của một Instructor (dựa trên instructorId)
  Stream<List<Course>> getInstructorCoursesStream(String instructorId) {
    return _db
        .collection('courses')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Lấy stream khóa học của một Student (khóa học mà student đã đăng ký)
  /// Tìm theo cả UID và email
  Stream<List<Course>> getStudentCoursesStream(String studentId, String studentEmail) {
    return _db
        .collection('courses')
        .snapshots()
        .map((snapshot) {
      // Filter courses that contain either studentId (UID) or studentEmail
      return snapshot.docs
          .map((doc) => Course.fromMap(doc.data(), doc.id))
          .where((course) => 
              course.studentIds.contains(studentId) || 
              course.studentIds.contains(studentEmail))
          .toList();
    });
  }

  /// Thêm student vào khóa học (enroll)
  Future<void> enrollStudentInCourse(String courseId, String studentId) async {
    await _db.collection('courses').doc(courseId).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  /// Xóa student khỏi khóa học (unenroll)
  Future<void> unenrollStudentFromCourse(String courseId, String studentId) async {
    await _db.collection('courses').doc(courseId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  /// Kiểm tra student đã đăng ký khóa học chưa
  Future<bool> isStudentEnrolled(String courseId, String studentId) async {
    final doc = await _db.collection('courses').doc(courseId).get();
    if (doc.exists && doc.data() != null) {
      final studentIds = List<String>.from(doc.data()?['studentIds'] ?? []);
      return studentIds.contains(studentId);
    }
    return false;
  }

  /// Lấy tất cả khóa học (cho Student duyệt và đăng ký)
  Stream<List<Course>> getAllCoursesStream() {
    return _db.collection('courses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // --- Materials / Assignments / Quizzes helpers ---

  /// Get materials for a course
  Stream<List<CourseMaterial>> getCourseMaterialsStream(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('materials')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseMaterial.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Add material (instructor only)
  Future<String> addMaterial(String courseId, Map<String, dynamic> materialData) async {
    final ref = await _db.collection('courses').doc(courseId).collection('materials').add(materialData);
    return ref.id;
  }

  /// Get assignments for a course
  Stream<List<Assignment>> getCourseAssignmentsStream(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('assignments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Assignment.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Add assignment
  Future<String> addAssignment(String courseId, Map<String, dynamic> assignmentData) async {
    final ref = await _db.collection('courses').doc(courseId).collection('assignments').add(assignmentData);
    return ref.id;
  }

  /// Submit assignment (adds a submission object into the submissions array)
  /// Submit assignment - stores submission under `submissions.{studentId}` so each student has a single entry
  Future<void> submitAssignment(String courseId, String assignmentId, Map<String, dynamic> submission) async {
    final studentId = submission['studentId'] as String?;
    if (studentId == null || studentId.isEmpty) {
      throw ArgumentError('submission must include studentId');
    }

    final docRef = _db.collection('courses').doc(courseId).collection('assignments').doc(assignmentId);
    // Use dot notation to set a map entry for the student and merge
    await docRef.set({
      'submissions': {studentId: submission}
    }, SetOptions(merge: true));
  }

  /// Get a single assignment document
  Future<Assignment?> getAssignment(String courseId, String assignmentId) async {
    final doc = await _db.collection('courses').doc(courseId).collection('assignments').doc(assignmentId).get();
    if (doc.exists && doc.data() != null) {
      return Assignment.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Stream a single assignment (useful for real-time submissions view)
  Stream<Assignment?> getAssignmentStream(String courseId, String assignmentId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('assignments')
        .doc(assignmentId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? Assignment.fromMap(doc.data()!, doc.id) : null);
  }

  /// Grade a student's submission (set grade and optional feedback)
  Future<void> gradeSubmission(String courseId, String assignmentId, String studentId, double grade, String? feedback) async {
    final updates = <String, dynamic>{};
    updates['submissions.$studentId.grade'] = grade;
    if (feedback != null) updates['submissions.$studentId.feedback'] = feedback;

    await _db.collection('courses').doc(courseId).collection('assignments').doc(assignmentId).update(updates);
  }

  /// Get quizzes for a course
  Stream<List<Quiz>> getCourseQuizzesStream(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Quiz.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Add quiz
  Future<String> addQuiz(String courseId, Map<String, dynamic> quizData) async {
    final ref = await _db.collection('courses').doc(courseId).collection('quizzes').add(quizData);
    return ref.id;
  }

  /// Submit quiz response
  /// Submit quiz response - store under `responses.{studentId}` so each student has a single response
  Future<void> submitQuizResponse(String courseId, String quizId, Map<String, dynamic> response) async {
    final studentId = response['studentId'] as String?;
    if (studentId == null || studentId.isEmpty) {
      throw ArgumentError('response must include studentId');
    }

    final docRef = _db.collection('courses').doc(courseId).collection('quizzes').doc(quizId);
    await docRef.set({
      'responses': {studentId: response}
    }, SetOptions(merge: true));
  }

  /// Get a single quiz document
  Future<Quiz?> getQuiz(String courseId, String quizId) async {
    final doc = await _db.collection('courses').doc(courseId).collection('quizzes').doc(quizId).get();
    if (doc.exists && doc.data() != null) return Quiz.fromMap(doc.data()!, doc.id);
    return null;
  }

  /// Stream a single quiz document
  Stream<Quiz?> getQuizStream(String courseId, String quizId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('quizzes')
        .doc(quizId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? Quiz.fromMap(doc.data()!, doc.id) : null);
  }

  /// Grade a student's quiz response (set score and optional feedback)
  Future<void> gradeQuizResponse(String courseId, String quizId, String studentId, double score, String? feedback) async {
    final updates = <String, dynamic>{};
    updates['responses.$studentId.score'] = score;
    if (feedback != null) updates['responses.$studentId.feedback'] = feedback;
    await _db.collection('courses').doc(courseId).collection('quizzes').doc(quizId).update(updates);
  }

  // --- Favorite Courses ---

  /// Get favorite courses stream for a student
  Stream<List<String>> getFavoriteCoursesStream(String studentId) {
    return _db
        .collection('users')
        .doc(studentId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return List<String>.from(data['favoriteCourses'] ?? []);
      }
      return <String>[];
    });
  }

  /// Toggle favorite course (add if not exists, remove if exists)
  Future<void> toggleFavoriteCourse(String studentId, String courseId) async {
    final userDoc = await _db.collection('users').doc(studentId).get();
    
    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      final favorites = List<String>.from(data['favoriteCourses'] ?? []);
      
      if (favorites.contains(courseId)) {
        // Remove from favorites
        await _db.collection('users').doc(studentId).update({
          'favoriteCourses': FieldValue.arrayRemove([courseId])
        });
      } else {
        // Add to favorites
        await _db.collection('users').doc(studentId).update({
          'favoriteCourses': FieldValue.arrayUnion([courseId])
        });
      }
    } else {
      // Create user doc with favorite
      await _db.collection('users').doc(studentId).set({
        'favoriteCourses': [courseId]
      }, SetOptions(merge: true));
    }
  }

  /// Check if course is favorite
  Future<bool> isFavoriteCourse(String studentId, String courseId) async {
    final userDoc = await _db.collection('users').doc(studentId).get();
    
    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      final favorites = List<String>.from(data['favoriteCourses'] ?? []);
      return favorites.contains(courseId);
    }
    return false;
  }

  // --- Comments / Discussion ---

  /// Get comments stream for a course
  Stream<List<Comment>> getCourseCommentsStream(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Add a comment to a course
  Future<String> addComment(Comment comment) async {
    final ref = await _db
        .collection('courses')
        .doc(comment.courseId)
        .collection('comments')
        .add(comment.toMap());
    return ref.id;
  }

  /// Delete a comment (only by owner or instructor)
  Future<void> deleteComment(String courseId, String commentId) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike(String courseId, String commentId, String userId) async {
    final commentRef = _db
        .collection('courses')
        .doc(courseId)
        .collection('comments')
        .doc(commentId);

    final commentDoc = await commentRef.get();
    if (commentDoc.exists && commentDoc.data() != null) {
      final data = commentDoc.data()!;
      final likes = List<String>.from(data['likes'] ?? []);

      if (likes.contains(userId)) {
        // Unlike
        await commentRef.update({
          'likes': FieldValue.arrayRemove([userId])
        });
      } else {
        // Like
        await commentRef.update({
          'likes': FieldValue.arrayUnion([userId])
        });
      }
    }
  }

  /// Get replies for a comment
  Stream<List<Comment>> getCommentRepliesStream(String courseId, String commentId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('comments')
        .where('replyToId', isEqualTo: commentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get comment count for a course
  Future<int> getCourseCommentCount(String courseId) async {
    final snapshot = await _db
        .collection('courses')
        .doc(courseId)
        .collection('comments')
        .where('replyToId', isEqualTo: null)
        .get();
    return snapshot.docs.length;
  }
}
