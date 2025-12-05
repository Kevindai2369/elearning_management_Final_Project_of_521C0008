import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../utils/file_handler.dart';
import '../../models/material_model.dart';

class UploadMaterialScreen extends StatefulWidget {
  final String courseId;
  const UploadMaterialScreen({super.key, required this.courseId});

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  PickedFileData? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await FileHandler.pickFile(dialogTitle: 'Chọn file tài liệu', fileType: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
    if (file != null) {
      if (!FileHandler.isFileSizeValid(file, 50)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File vượt quá 50MB')));
        return;
      }
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _uploadMaterial() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn file')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('=== UPLOAD MATERIAL START ===');
      
      // Check authentication
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Bạn chưa đăng nhập. Vui lòng đăng nhập lại.');
      }
      
      final userId = currentUser.uid;
      debugPrint('User ID: $userId');
      debugPrint('User email: ${currentUser.email}');
      debugPrint('Course ID: ${widget.courseId}');
      
      final fileName = _selectedFile!.name;
      debugPrint('File name: $fileName');
      debugPrint('File size: ${_selectedFile!.size}');
      
      if (_selectedFile!.bytes == null) {
        throw Exception('Không thể đọc dữ liệu file. Vui lòng thử lại.');
      }
      
      debugPrint('File bytes available: ${_selectedFile!.bytes!.length}');
      
      // Show uploading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang upload file...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Add timestamp to filename like assignment does
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithTimestamp = '${timestamp}_$fileName';
      
      debugPrint('Calling uploadMaterial...');
      final fileUrl = await StorageService().uploadCourseMaterial(
        courseId: widget.courseId,
        fileName: fileNameWithTimestamp,
        fileBytes: _selectedFile!.bytes!,
      );
      debugPrint('Upload successful, URL: $fileUrl');

      final material = CourseMaterial(
        id: '',
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: _selectedFile!.size,
        createdAt: DateTime.now(),
        createdBy: userId,
      );

      debugPrint('Saving to Firestore...');
      await _firestoreService.addMaterial(widget.courseId, material.toMap());
      debugPrint('Saved to Firestore successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Upload thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
      debugPrint('=== UPLOAD MATERIAL SUCCESS ===');
    } on FirebaseException catch (e) {
      debugPrint('=== UPLOAD MATERIAL FIREBASE ERROR ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Plugin: ${e.plugin}');
      
      String errorMessage = 'Lỗi Firebase: ';
      if (e.code == 'storage/unauthorized') {
        errorMessage += 'Bạn không có quyền upload. Vui lòng kiểm tra Firebase Storage Rules.';
      } else if (e.code == 'storage/canceled') {
        errorMessage += 'Upload bị hủy.';
      } else if (e.code == 'storage/unknown') {
        errorMessage += 'Lỗi không xác định. Vui lòng kiểm tra:\n'
            '1. Firebase Storage đã được enable\n'
            '2. Storage Rules đã được cấu hình\n'
            '3. Kết nối internet';
      } else {
        errorMessage += '${e.message}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('=== UPLOAD MATERIAL ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Tài Liệu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              if (_selectedFile == null) ...[
                const Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('Chưa chọn file'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _pickFile, child: const Text('Chọn File (PDF/DOC)')),
              ] else ...[
                Text(_selectedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Size: ${FileHandler.getFileSizeInMB(_selectedFile!).toStringAsFixed(2)} MB'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _pickFile, child: const Text('Chọn File Khác')),
              ]
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _isLoading ? null : _uploadMaterial, child: _isLoading ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Upload')),
        ]),
      ),
    );
  }
}
