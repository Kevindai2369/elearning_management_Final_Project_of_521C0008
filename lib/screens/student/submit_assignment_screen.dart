import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/assignment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../utils/file_handler.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final String courseId;
  final Assignment assignment;

  const SubmitAssignmentScreen({
    super.key,
    required this.courseId,
    required this.assignment,
  });

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  PickedFileData? _selectedFile;
  bool _isLoading = false;
  double _uploadProgress = 0;
  AssignmentSubmission? _existingSubmission;

  @override
  void initState() {
    super.initState();
    _checkExistingSubmission();
  }

  void _checkExistingSubmission() {
    final userId = AuthService().currentUser?.uid ?? '';
    try {
      _existingSubmission = widget.assignment.submissions.firstWhere(
        (sub) => sub.studentId == userId,
      );
      setState(() {});
    } catch (e) {
      _existingSubmission = null;
    }
  }

  Future<void> _pickFile() async {
    final file = await FileHandler.pickFile(
      dialogTitle: 'Chọn file bài làm',
      fileType: FileType.custom,
      allowedExtensions: ['rar', 'zip', '7z'],
    );

    if (file != null) {
      // Check file size (max 50MB)
      if (!FileHandler.isFileSizeValid(file, 50)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File vượt quá 50MB. Vui lòng nén lại file.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validate file type
      final fileName = file.name;
      if (!FileHandler.isValidAssignmentFile(fileName)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chỉ chấp nhận file .rar, .zip, .7z'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _selectedFile = file);
    }
  }

  Future<void> _downloadAssignmentFile() async {
    try {
      final url = Uri.parse(widget.assignment.fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn file bài làm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirm submission
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nộp bài'),
        content: Text(
          _existingSubmission != null
              ? 'Bạn đã nộp bài trước đó. Nộp lại sẽ ghi đè bài cũ. Tiếp tục?'
              : 'Bạn có chắc muốn nộp bài này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nộp Bài'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      final userId = AuthService().currentUser?.uid ?? '';
      final userData = await AuthService().getUserData(userId);
      final studentName = userData?['fullName'] ?? 'Unknown';
      
      final fileName = _selectedFile!.name;

      if (_selectedFile!.bytes == null) {
        throw Exception('No file data available');
      }

      // Upload file to Firebase Storage
      final fileUrl = await StorageService().uploadAssignmentSubmission(
        courseId: widget.courseId,
        assignmentId: widget.assignment.id,
        studentId: userId,
        fileBytes: _selectedFile!.bytes!,
        fileName: fileName,
      );

      // Create submission data
      final submissionData = {
        'studentId': userId,
        'studentName': studentName,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'submittedAt': DateTime.now().toIso8601String(),
        'grade': null,
        'feedback': null,
      };

      // Save to Firestore
      await FirestoreService().submitAssignment(
        widget.courseId,
        widget.assignment.id,
        submissionData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nộp bài thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final now = DateTime.now();
    final isOverdue = now.isAfter(widget.assignment.dueDate);
    final daysLeft = widget.assignment.dueDate.difference(now).inDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nộp Bài Tập'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Assignment info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assignment.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.assignment.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hạn nộp: ${widget.assignment.dueDate.day}/${widget.assignment.dueDate.month}/${widget.assignment.dueDate.year} ${widget.assignment.dueDate.hour}:${widget.assignment.dueDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (!isOverdue) ...[
                    const SizedBox(height: 8),
                    Text(
                      daysLeft > 0
                          ? 'Còn $daysLeft ngày'
                          : 'Hết hạn hôm nay',
                      style: TextStyle(
                        color: daysLeft > 3 ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Đã quá hạn',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _downloadAssignmentFile,
                    icon: const Icon(Icons.download),
                    label: Text('Tải đề bài (${widget.assignment.fileName})'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Existing submission status
          if (_existingSubmission != null) ...[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Đã nộp bài',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('File: ${_existingSubmission!.fileName}'),
                    Text(
                      'Thời gian: ${_existingSubmission!.submittedAt.day}/${_existingSubmission!.submittedAt.month}/${_existingSubmission!.submittedAt.year} ${_existingSubmission!.submittedAt.hour}:${_existingSubmission!.submittedAt.minute.toString().padLeft(2, '0')}',
                    ),
                    if (_existingSubmission!.grade != null) ...[
                      const Divider(height: 24),
                      Text(
                        'Điểm: ${_existingSubmission!.grade}/100',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_existingSubmission!.feedback != null &&
                          _existingSubmission!.feedback!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Nhận xét: ${_existingSubmission!.feedback}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Chưa được chấm điểm',
                        style: TextStyle(
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // File picker section
          Text(
            _existingSubmission != null ? 'Nộp lại bài mới' : 'Chọn file bài làm',
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
                    'Chấp nhận: .rar, .zip, .7z (< 50MB)',
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
                    'Kích thước: ${FileHandler.getFileSizeInMB(_selectedFile!).toStringAsFixed(2)} MB',
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

          // Submit button
          ElevatedButton(
            onPressed: _isLoading ? null : _submitAssignment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _existingSubmission != null ? 'Nộp Lại Bài' : 'Nộp Bài',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 16),

          // Warning card
          if (isOverdue)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bài tập đã quá hạn. Nộp muộn có thể bị trừ điểm.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
