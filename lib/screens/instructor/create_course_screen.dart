import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  Color _selectedColor = Colors.blue;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.indigo,
    Colors.teal,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên khóa học')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid ?? '';
      final userData = await _authService.getUserData(userId);
      final instructorName = userData?['fullName'] ?? 'Unknown';

      // Convert Color to hex string (RGB format)
      final r = ((_selectedColor.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
      final g = ((_selectedColor.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
      final b = ((_selectedColor.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
      final colorHex = '#$r$g$b';

      final course = Course(
        id: '',
        name: name,
        instructorId: userId,
        instructorName: instructorName,
        description: description,
        colorHex: colorHex,
        studentIds: [],
        createdAt: DateTime.now(),
      );

      await _firestoreService.addCourse(course);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Khóa học đã được tạo!')));
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
      appBar: AppBar(title: const Text('Tạo Khóa Học')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tên Khóa Học', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Mô Tả', border: OutlineInputBorder()), maxLines: 4),
            const SizedBox(height: 16),
            Text('Chọn màu sắc:'),
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: _colorOptions.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _selectedColor == color ? Colors.black : Colors.grey, width: _selectedColor == color ? 2 : 1)),
                ),
              );
            }).toList()),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _isLoading ? null : _createCourse, child: _isLoading ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Tạo Khóa Học')),
          ],
        ),
      ),
    );
  }
}
