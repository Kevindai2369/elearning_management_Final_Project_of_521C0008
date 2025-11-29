import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Wrapper class for file data that works on both web and mobile
class PickedFileData {
  final String name;
  final int size;
  final Uint8List? bytes; // For web
  final String? path; // For mobile
  
  PickedFileData({
    required this.name,
    required this.size,
    this.bytes,
    this.path,
  });
  
  bool get isWeb => kIsWeb;
  
  /// Get file for mobile platforms (returns null on web)
  File? get file {
    if (kIsWeb) return null; // Always null on web
    return path != null ? File(path!) : null;
  }
}

class FileHandler {
  /// Pick a file - works on both web and mobile
  static Future<PickedFileData?> pickFile({
    String? dialogTitle,
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
        withData: true, // Always load bytes for consistency
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // On web, file.path will be null - this is expected behavior
        // The warning from file_picker library can be safely ignored
        return PickedFileData(
          name: file.name,
          size: file.size,
          bytes: file.bytes,
          path: kIsWeb ? null : file.path,
        );
      }
    } catch (e) {
      // Only log actual errors, not warnings about path being null on web
      final errorMsg = e.toString().toLowerCase();
      if (!errorMsg.contains('path') && !errorMsg.contains('null')) {
        debugPrint('Error picking file: $e');
        rethrow; // Rethrow actual errors
      }
      // Silently ignore path-related warnings on web
    }
    return null;
  }

  /// Check if file size is valid
  static bool isFileSizeValid(PickedFileData fileData, int maxSizeInMB) {
    final maxSize = maxSizeInMB * 1024 * 1024;
    return fileData.size <= maxSize;
  }

  /// Get file size in MB
  static double getFileSizeInMB(PickedFileData fileData) {
    return fileData.size / (1024 * 1024);
  }

  /// Check if file is valid assignment file type
  static bool isValidAssignmentFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const valid = ['rar', 'zip', '7z'];
    return valid.contains(ext);
  }

  /// Check if file is valid material file type
  static bool isValidMaterialFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const valid = ['pdf', 'doc', 'docx', 'txt'];
    return valid.contains(ext);
  }
  
  /// Legacy method for backward compatibility (mobile only)
  @Deprecated('Use pickFile() instead which returns PickedFileData')
  static Future<File?> pickFileLegacy({
    String? dialogTitle,
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    if (kIsWeb) {
      debugPrint('Warning: pickFileLegacy does not work on web. Use pickFile() instead.');
      return null;
    }
    
    final fileData = await pickFile(
      dialogTitle: dialogTitle,
      fileType: fileType,
      allowedExtensions: allowedExtensions,
    );
    
    return fileData?.file;
  }
}
