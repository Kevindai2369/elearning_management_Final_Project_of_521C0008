import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Simple file picker that works on both web and mobile
class SimpleFileHandler {
  /// Pick a file and return bytes + name
  static Future<PickedFile?> pickFile({
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: true, // Always get bytes
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      if (file.bytes != null) {
        return PickedFile(
          name: file.name,
          bytes: file.bytes!,
          size: file.size,
        );
      }
    }
    
    return null;
  }
}

/// Simple file data class
class PickedFile {
  final String name;
  final Uint8List bytes;
  final int size;

  PickedFile({
    required this.name,
    required this.bytes,
    required this.size,
  });
}
