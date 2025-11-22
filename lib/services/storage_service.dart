import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to `path` (e.g. 'uploads/avatars/user123.png') and return the download URL
  /// Upload a file and optionally report progress via [onProgress] (0.0 - 1.0).
  /// Returns the download URL when complete.
  Future<String> uploadFile(String path, File file, {void Function(double progress)? onProgress}) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);

    // Listen for progress
    final completer = Completer<String>();

    uploadTask.snapshotEvents.listen((TaskSnapshot snap) async {
      final total = snap.totalBytes;
      final transferred = snap.bytesTransferred;
      if (total != 0) {
        final progress = transferred / total;
        try {
          if (onProgress != null) onProgress(progress);
        } catch (_) {}
      }
      if (snap.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        if (!completer.isCompleted) completer.complete(url);
      }
      if (snap.state == TaskState.error) {
        if (!completer.isCompleted) completer.completeError('Upload failed');
      }
    }, onError: (e) {
      if (!completer.isCompleted) completer.completeError(e);
    });

    return completer.future;
  }

  /// Delete file at path
  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }
}
