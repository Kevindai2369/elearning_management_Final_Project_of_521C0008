import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

class CSVHandler {
  static Future<List<Map<String, String>>> parseStudentCSV(File file) async {
    final input = file.openRead();
    final content = await input.transform(utf8.decoder).join();
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

  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
