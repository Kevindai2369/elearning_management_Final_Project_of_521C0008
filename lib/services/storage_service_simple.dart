import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Simple storage service for uploading files
class SimpleStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload any file and return download URL
  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      debugPrint('=== STORAGE: uploadFile START ===');
      debugPrint('Path: $path');
      debugPrint('Bytes: ${bytes.length}');
      debugPrint('Content type: $contentType');
      
      final ref = _storage.ref().child(path);
      debugPrint('Storage ref created: ${ref.fullPath}');
      
      final metadata = contentType != null
          ? SettableMetadata(contentType: contentType)
          : null;
      
      debugPrint('Starting putData...');
      final uploadTask = ref.putData(bytes, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');
      });
      
      await uploadTask;
      debugPrint('putData completed');
      
      debugPrint('Getting download URL...');
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Download URL: $downloadUrl');
      debugPrint('=== STORAGE: uploadFile SUCCESS ===');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('=== STORAGE: uploadFile ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Upload avatar
  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    try {
      debugPrint('=== STORAGE: uploadAvatar START ===');
      debugPrint('User ID: $userId');
      debugPrint('Bytes length: ${bytes.length}');
      
      // Use fixed filename to overwrite old avatar
      final path = 'avatars/$userId/avatar.jpg';
      debugPrint('Upload path: $path');
      
      // Try to delete old avatar first (ignore errors if it doesn't exist)
      try {
        debugPrint('Attempting to delete old avatar...');
        final ref = _storage.ref().child(path);
        await ref.delete();
        debugPrint('Old avatar deleted');
      } catch (e) {
        debugPrint('No old avatar to delete (or error): $e');
      }
      
      debugPrint('Calling uploadFile...');
      final url = await uploadFile(
        path: path,
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      debugPrint('uploadFile returned URL: $url');
      debugPrint('=== STORAGE: uploadAvatar SUCCESS ===');
      return url;
    } catch (e, stackTrace) {
      debugPrint('=== STORAGE: uploadAvatar ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Upload course material
  Future<String> uploadMaterial(String courseId, String fileName, Uint8List bytes) async {
    final path = 'courses/$courseId/materials/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return uploadFile(path: path, bytes: bytes);
  }

  /// Upload assignment submission
  Future<String> uploadSubmission(
    String courseId,
    String assignmentId,
    String studentId,
    String fileName,
    Uint8List bytes,
  ) async {
    final path = 'courses/$courseId/assignments/$assignmentId/submissions/$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return uploadFile(path: path, bytes: bytes);
  }

  /// Delete file
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }
}
