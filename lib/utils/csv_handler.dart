import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'file_handler.dart';

class CSVHandler {
  /// Parse CSV from File (mobile)
  static Future<List<Map<String, String>>> parseStudentCSV(File file) async {
    final input = file.openRead();
    final content = await input.transform(utf8.decoder).join();
    return _parseCSVContent(content);
  }

  /// Parse CSV from PickedFileData (works on both web and mobile)
  static Future<List<Map<String, String>>> parseStudentCSVFromData(PickedFileData fileData) async {
    // Always use bytes since we set withData: true in FileHandler
    if (fileData.bytes == null) {
      throw Exception('No bytes available for CSV file');
    }
    
    final content = utf8.decode(fileData.bytes!);
    return _parseCSVContent(content);
  }

  /// Parse CSV content string
  static List<Map<String, String>> _parseCSVContent(String content) {
    final rows = const CsvToListConverter().convert(content);
    final students = <Map<String, String>>[];
    
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 2) {
        final email = row[0].toString().trim();
        final fullName = row[1].toString().trim();
        students.add({'email': email, 'fullName': fullName});
      }
    }
    return students;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
}
