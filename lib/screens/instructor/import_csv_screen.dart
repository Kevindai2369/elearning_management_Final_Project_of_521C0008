import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/csv_handler.dart';
import '../../services/firestore_service.dart';
import '../../utils/file_handler.dart';

class ImportCSVScreen extends StatefulWidget {
  final String courseId;
  const ImportCSVScreen({super.key, required this.courseId});

  @override
  State<ImportCSVScreen> createState() => _ImportCSVScreenState();
}

class _ImportCSVScreenState extends State<ImportCSVScreen> {
  File? _csvFile;
  bool _isLoading = false;
  final _firestoreService = FirestoreService();
  Future<void> _pickCSV() async {
    final file = await FileHandler.pickFile(dialogTitle: 'Chọn CSV', fileType: FileType.custom, allowedExtensions: ['csv']);
    if (file != null) setState(() => _csvFile = file);
  }

  Future<void> _import() async {
    if (_csvFile == null) return;
    setState(() => _isLoading = true);
    try {
      final students = await CSVHandler.parseStudentCSV(_csvFile!);
      int added = 0;
      for (final s in students) {
        final email = s['email'] ?? '';
        if (!CSVHandler.isValidEmail(email)) continue;
        // Note: For simplicity we add the email string into the studentIds array
  await _firestoreService.setDoc('courses', widget.courseId, {
          'studentIds': FieldValue.arrayUnion([email])
        }, merge: true);
        added++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $added students')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('CSV format: email,fullName'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _pickCSV, child: const Text('Chọn CSV')),
          const SizedBox(height: 12),
          if (_csvFile != null) Text(_csvFile!.path.split(Platform.pathSeparator).last),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _isLoading ? null : _import, child: _isLoading ? const CircularProgressIndicator() : const Text('Import')),
        ]),
      ),
    );
  }
}
