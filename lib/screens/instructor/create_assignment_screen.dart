import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String courseId;

  const CreateAssignmentScreen({super.key, required this.courseId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  PlatformFile? _selectedFile;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: kIsWeb, // Important: Load bytes on web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (max 50MB)
        if (file.size > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File vượt quá 50MB. Vui lòng chọn file nhỏ hơn.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Validate file type
        final ext = file.extension?.toLowerCase();
        if (ext == null || !['pdf', 'doc', 'docx'].contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chỉ chấp nhận file PDF, DOC, DOCX'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => _selectedFile = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn file: $e')),
        );
      }
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      
      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn file đề bài'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      final userId = AuthService().currentUser?.uid ?? '';
      final fileName = _selectedFile!.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Upload file to Firebase Storage
      if (_selectedFile!.bytes == null) {
        throw Exception('No file data available');
      }
      
      final fileUrl = await StorageService().uploadCourseMaterial(
        courseId: widget.courseId,
        fileName: '${timestamp}_$fileName',
        fileBytes: _selectedFile!.bytes!,
      );

      // Create assignment data
      final assignmentData = {
        'courseId': widget.courseId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fileUrl': fileUrl,
        'fileName': fileName,
        'dueDate': _dueDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': userId,
        'submissions': {}, // Empty map for submissions
      };

      // Save to Firestore
      await FirestoreService().addAssignment(widget.courseId, assignmentData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo bài tập thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Bài Tập Mới'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createAssignment,
              tooltip: 'Lưu Bài Tập',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề Bài Tập *',
                hintText: 'Ví dụ: Bài tập tuần 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả *',
                hintText: 'Mô tả yêu cầu bài tập...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Due Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Hạn nộp'),
                subtitle: Text(
                  '${_dueDate.day}/${_dueDate.month}/${_dueDate.year} ${_dueDate.hour}:${_dueDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit),
                onTap: _selectDueDate,
              ),
            ),
            const SizedBox(height: 24),

            // File picker section
            Text(
              'File Đề Bài *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (_selectedFile == null) ...[
                    const Icon(
                      Icons.cloud_upload,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa chọn file',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chấp nhận: PDF, DOC, DOCX (< 50MB)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Chọn File'),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kích thước: ${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _pickFile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Chọn File Khác'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() => _selectedFile = null);
                                },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upload progress
            if (_isLoading && _uploadProgress > 0) ...[
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(
                'Đang tải lên... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],

            // Create button
            ElevatedButton(
              onPressed: _isLoading ? null : _createAssignment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Tạo Bài Tập',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Học sinh sẽ nộp bài dưới dạng file .rar hoặc .zip',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
