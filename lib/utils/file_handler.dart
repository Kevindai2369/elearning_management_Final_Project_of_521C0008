import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class FileHandler {
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
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  static bool isFileSizeValid(File file, int maxSizeInMB) {
    final fileSize = file.lengthSync();
    final maxSize = maxSizeInMB * 1024 * 1024;
    return fileSize <= maxSize;
  }

  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  static bool isValidAssignmentFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const valid = ['rar', 'zip', '7z'];
    return valid.contains(ext);
  }

  static bool isValidMaterialFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const valid = ['pdf', 'doc', 'docx', 'txt'];
    return valid.contains(ext);
  }
}
