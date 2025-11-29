import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class FavoriteCoursesScreen extends StatefulWidget {
  const FavoriteCoursesScreen({super.key});

  @override
  State<FavoriteCoursesScreen> createState() => _FavoriteCoursesScreenState();
}

class _FavoriteCoursesScreenState extends State<FavoriteCoursesScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khóa Học Yêu Thích'),
      ),
      body: StreamBuilder<List<String>>(
        stream: _firestoreService.getFavoriteCoursesStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final favoriteCourseIds = snapshot.data ?? [];

          if (favoriteCourseIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có khóa học yêu thích',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bấm vào icon ⭐ trong khóa học để thêm vào yêu thích',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Course>>(
            stream: _firestoreService.getAllCoursesStream(),
            builder: (context, coursesSnapshot) {
              if (!coursesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allCourses = coursesSnapshot.data!;
              final favoriteCourses = allCourses
                  .where((course) => favoriteCourseIds.contains(course.id))
                  .toList();

              if (favoriteCourses.isEmpty) {
                return const Center(
                  child: Text('Không tìm thấy khóa học yêu thích'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoriteCourses.length,
                itemBuilder: (context, index) {
                  final course = favoriteCourses[index];
                  return _buildCourseCard(context, course);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final userId = _authService.currentUser?.uid ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/course/${course.id}', arguments: course);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: course.getColor(), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    onPressed: () async {
                      await _firestoreService.toggleFavoriteCourse(userId, course.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa khỏi yêu thích')),
                      );
                    },
                    tooltip: 'Xóa khỏi yêu thích',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Giảng viên: ${course.instructorName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Học sinh: ${course.studentIds.length}'),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/course/${course.id}', arguments: course);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Vào Học'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
