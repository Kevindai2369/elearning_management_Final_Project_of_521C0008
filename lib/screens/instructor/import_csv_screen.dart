import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/csv_handler.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/file_handler.dart';

class ImportCSVScreen extends StatefulWidget {
  final String courseId;
  const ImportCSVScreen({super.key, required this.courseId});

  @override
  State<ImportCSVScreen> createState() => _ImportCSVScreenState();
}

class _ImportCSVScreenState extends State<ImportCSVScreen> {
  PickedFileData? _csvFile;
  List<Map<String, dynamic>>? _studentsWithStatus;
  bool _isLoading = false;
  bool _isParsing = false;
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  
  Future<void> _pickCSV() async {
    final file = await FileHandler.pickFile(
      dialogTitle: 'Chọn CSV',
      fileType: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file != null) {
      setState(() {
        _csvFile = file;
        _studentsWithStatus = null;
      });
      await _parseAndCheckStudents();
    }
  }

  Future<void> _parseAndCheckStudents() async {
    if (_csvFile == null) return;
    
    setState(() => _isParsing = true);
    try {
      final students = await CSVHandler.parseStudentCSVFromData(_csvFile!);
      final studentsWithStatus = <Map<String, dynamic>>[];
      
      for (final student in students) {
        final email = student['email'] ?? '';
        final fullName = student['fullName'] ?? '';
        
        if (!CSVHandler.isValidEmail(email)) {
          studentsWithStatus.add({
            'email': email,
            'fullName': fullName,
            'status': 'invalid_email',
            'statusText': 'Email không hợp lệ',
            'statusColor': Colors.red,
          });
          continue;
        }
        
        // Check if user exists in system
        final userData = await _authService.getUserByEmail(email);
        if (userData != null) {
          studentsWithStatus.add({
            'email': email,
            'fullName': userData['fullName'] ?? fullName,
            'uid': userData['uid'],
            'status': 'registered',
            'statusText': 'Đã có tài khoản',
            'statusColor': Colors.green,
          });
        } else {
          studentsWithStatus.add({
            'email': email,
            'fullName': fullName,
            'status': 'not_registered',
            'statusText': 'Chưa đăng ký',
            'statusColor': Colors.orange,
          });
        }
      }
      
      setState(() {
        _studentsWithStatus = studentsWithStatus;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi parse CSV: $e')),
        );
      }
    } finally {
      setState(() => _isParsing = false);
    }
  }

  Future<void> _import() async {
    if (_studentsWithStatus == null || _studentsWithStatus!.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      int added = 0;
      final studentIdsToAdd = <String>[];
      
      for (final student in _studentsWithStatus!) {
        final status = student['status'] as String;
        
        // Skip invalid emails
        if (status == 'invalid_email') continue;
        
        // Add UID if registered, email if not registered
        if (status == 'registered' && student['uid'] != null) {
          studentIdsToAdd.add(student['uid'] as String);
        } else {
          studentIdsToAdd.add(student['email'] as String);
        }
        added++;
      }
      
      // Add all students at once
      if (studentIdsToAdd.isNotEmpty) {
        await _firestoreService.setDoc('courses', widget.courseId, {
          'studentIds': FieldValue.arrayUnion(studentIdsToAdd)
        }, merge: true);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm $added sinh viên vào khóa học'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Danh Sách Sinh Viên'),
        actions: [
          if (_studentsWithStatus != null && _studentsWithStatus!.isNotEmpty)
            TextButton.icon(
              onPressed: _isLoading ? null : _import,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                _isLoading ? 'Đang import...' : 'Import',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Instructions card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Hướng dẫn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('1. File CSV phải có định dạng: email,fullName'),
                  const Text('2. Dòng đầu tiên là header (sẽ bị bỏ qua)'),
                  const Text('3. Ví dụ:'),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'email,fullName\nstudent1@example.com,Nguyen Van A\nstudent2@example.com,Tran Thi B',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Pick file button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isParsing ? null : _pickCSV,
              icon: const Icon(Icons.upload_file),
              label: Text(_csvFile == null ? 'Chọn File CSV' : 'Chọn File Khác'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          
          if (_csvFile != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'File: ${_csvFile!.name}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Loading or student list
          if (_isParsing)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang phân tích file CSV...'),
                  ],
                ),
              ),
            )
          else if (_studentsWithStatus != null && _studentsWithStatus!.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Tổng số',
                          _studentsWithStatus!.length.toString(),
                          Colors.blue,
                        ),
                        _buildSummaryItem(
                          'Đã có TK',
                          _studentsWithStatus!.where((s) => s['status'] == 'registered').length.toString(),
                          Colors.green,
                        ),
                        _buildSummaryItem(
                          'Chưa đăng ký',
                          _studentsWithStatus!.where((s) => s['status'] == 'not_registered').length.toString(),
                          Colors.orange,
                        ),
                        _buildSummaryItem(
                          'Lỗi',
                          _studentsWithStatus!.where((s) => s['status'] == 'invalid_email').length.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                  
                  // Student list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _studentsWithStatus!.length,
                      itemBuilder: (context, index) {
                        final student = _studentsWithStatus![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (student['statusColor'] as Color).withValues(alpha: 0.2),
                              child: Icon(
                                student['status'] == 'registered' 
                                    ? Icons.check_circle 
                                    : student['status'] == 'invalid_email'
                                        ? Icons.error
                                        : Icons.email,
                                color: student['statusColor'] as Color,
                              ),
                            ),
                            title: Text(
                              student['fullName'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student['email'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  student['statusText'] ?? '',
                                  style: TextStyle(
                                    color: student['statusColor'] as Color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else if (_csvFile != null)
            const Expanded(
              child: Center(
                child: Text('Không tìm thấy sinh viên nào trong file CSV'),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Chọn file CSV để bắt đầu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
