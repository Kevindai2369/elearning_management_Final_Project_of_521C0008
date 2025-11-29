import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload avatar to Firebase Storage
  /// Returns download URL
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Create reference to avatars/{userId}/{fileName}
      final ref = _storage.ref().child('avatars/$userId/$fileName');
      
      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload file
      final uploadTask = ref.putData(imageBytes, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi upload avatar: $e');
    }
  }

  /// Delete avatar from Firebase Storage
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      final ref = _storage.refFromURL(avatarUrl);
      await ref.delete();
    } catch (e) {
      // Ignore error if file doesn't exist
      if (!e.toString().contains('object-not-found')) {
        throw Exception('Lỗi xóa avatar: $e');
      }
    }
  }

  /// Upload course material
  Future<String> uploadCourseMaterial({
    required String courseId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child('courses/$courseId/materials/$fileName');
      
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
      );
      
      final uploadTask = ref.putData(fileBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi upload tài liệu: $e');
    }
  }

  /// Upload assignment submission
  Future<String> uploadAssignmentSubmission({
    required String courseId,
    required String assignmentId,
    required String studentId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('courses/$courseId/assignments/$assignmentId/submissions/$studentId/$fileName');
      
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
      );
      
      final uploadTask = ref.putData(fileBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi upload bài nộp: $e');
    }
  }

  /// Get content type from file extension
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      
      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      
      // Default
      default:
        return 'application/octet-stream';
    }
  }

  /// Get upload progress stream
  Stream<double> getUploadProgress(UploadTask task) {
    return task.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
