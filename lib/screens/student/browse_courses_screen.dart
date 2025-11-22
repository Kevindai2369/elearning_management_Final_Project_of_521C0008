import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';

class BrowseCoursesScreen extends StatefulWidget {
  const BrowseCoursesScreen({super.key});

  @override
  State<BrowseCoursesScreen> createState() => _BrowseCoursesScreenState();
}

class _BrowseCoursesScreenState extends State<BrowseCoursesScreen> {
  final _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt Khóa Học')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khóa học...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: _firestoreService.getAllCoursesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var courses = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  courses = courses.where((c) => c.name.toLowerCase().contains(_searchQuery) || c.instructorName.toLowerCase().contains(_searchQuery)).toList();
                }
                if (courses.isEmpty) return const Center(child: Text('Không tìm thấy khóa học'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(course.name),
                        subtitle: Text('Giảng viên: ${course.instructorName}'),
                        trailing: ElevatedButton(
                          child: const Text('Chi tiết'),
                          onPressed: () {
                            Navigator.pushNamed(context, '/course/${course.id}', arguments: course);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
