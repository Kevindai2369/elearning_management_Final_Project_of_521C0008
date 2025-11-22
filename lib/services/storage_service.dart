import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to `path` (e.g. 'uploads/avatars/user123.png') and return the download URL
  Future<String> uploadFile(String path, File file) async {
    final ref = _storage.ref().child(path);
  await ref.putFile(file);
  return await ref.getDownloadURL();
  }

  /// Delete file at path
  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }
}
