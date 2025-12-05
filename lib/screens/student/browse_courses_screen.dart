import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_error_state.dart';
import '../../widgets/course/course_card.dart';

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
      appBar: AppBar(
        title: const Text('Duyệt Khóa Học'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khóa học, giảng viên...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textHint,
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingM,
                ),
              ),
            ),
          ),
          // Course list
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: _firestoreService.getAllCoursesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AppLoading.shimmerList();
                }

                if (snapshot.hasError) {
                  return AppErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  );
                }

                var courses = snapshot.data ?? [];
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  courses = courses.where((c) {
                    return c.name.toLowerCase().contains(_searchQuery) ||
                        c.instructorName.toLowerCase().contains(_searchQuery) ||
                        c.description.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (courses.isEmpty) {
                  return AppEmptyState(
                    icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.school_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'Không tìm thấy khóa học'
                        : 'Chưa có khóa học nào',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Thử tìm kiếm với từ khóa khác'
                        : 'Các khóa học sẽ xuất hiện ở đây',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return CourseCard(
                      course: course,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/course/${course.id}',
                          arguments: course,
                        );
                      },
                      trailing: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/course/${course.id}',
                            arguments: course,
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Xem'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
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
