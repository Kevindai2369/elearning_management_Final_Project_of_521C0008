import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service_simple.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề')));
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn file')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.uid ?? '';
      final fileName = _selectedFile!.name;
      
      if (_selectedFile!.bytes == null) {
        throw Exception('No file data available');
      }
      
      final fileUrl = await SimpleStorageService().uploadMaterial(
        widget.courseId,
        fileName,
        _selectedFile!.bytes!,
      );

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

      await _firestoreService.addMaterial(widget.courseId, material.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload thành công')));
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
