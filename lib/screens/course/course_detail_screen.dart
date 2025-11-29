import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/material_model.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import 'quiz_take_screen.dart';
import '../student/submit_assignment_screen.dart';
import 'course_discussion_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final userId = _authService.currentUser?.uid ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        actions: [
          // Favorite button for students
          FutureBuilder<Map<String, dynamic>?>(
            future: _authService.getUserData(userId),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              final role = userData?['role'] ?? 'student';
              
              if (role != 'student') return const SizedBox.shrink();
              
              return StreamBuilder<List<String>>(
                stream: _firestoreService.getFavoriteCoursesStream(userId),
                builder: (context, favSnapshot) {
                  final favorites = favSnapshot.data ?? [];
                  final isFavorite = favorites.contains(course.id);
                  
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () async {
                      await _firestoreService.toggleFavoriteCourse(userId, course.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite 
                              ? 'Đã xóa khỏi yêu thích' 
                              : 'Đã thêm vào yêu thích'
                          ),
                        ),
                      );
                    },
                    tooltip: isFavorite ? 'Xóa khỏi yêu thích' : 'Thêm vào yêu thích',
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tài liệu'), 
            Tab(text: 'Bài tập'), 
            Tab(text: 'Quiz'),
            Tab(text: 'Thảo luận'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _materialsTab(course),
          _assignmentsTab(course),
          _quizzesTab(course),
          _discussionTab(course),
        ],
      ),
    );
  }

  Widget _materialsTab(Course course) {
    return StreamBuilder<List<CourseMaterial>>(
      stream: _firestoreService.getCourseMaterialsStream(course.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final materials = snapshot.data!;
        if (materials.isEmpty) return const Center(child: Text('Chưa có tài liệu'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final m = materials[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(m.title),
                subtitle: Text(m.description.isNotEmpty ? m.description : m.fileName),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadMaterial(m),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadMaterial(CourseMaterial material) async {
    try {
      final url = Uri.parse(material.fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở file')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Widget _assignmentsTab(Course course) {
    final userId = _authService.currentUser?.uid ?? '';
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserData(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final userData = userSnapshot.data;
        final userRole = userData?['role'] ?? 'student';
        final isInstructor = userRole == 'instructor';
        
        return StreamBuilder<List<Assignment>>(
          stream: _firestoreService.getCourseAssignmentsStream(course.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final assignments = snapshot.data!;
            if (assignments.isEmpty) return const Center(child: Text('Chưa có bài tập'));
            
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final a = assignments[index];
                final now = DateTime.now();
                final isOverdue = now.isAfter(a.dueDate);
                final daysLeft = a.dueDate.difference(now).inDays;
                
                // Check if student has submitted
                final hasSubmitted = a.submissions.any((sub) => sub.studentId == userId);
                final submission = hasSubmitted 
                    ? a.submissions.firstWhere((sub) => sub.studentId == userId)
                    : null;
                
                return Card(
                  child: ListTile(
                    leading: Icon(
                      hasSubmitted ? Icons.check_circle : Icons.assignment,
                      color: hasSubmitted ? Colors.green : (isOverdue ? Colors.red : null),
                    ),
                    title: Text(a.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (a.description.isNotEmpty) ...[
                          Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          'Hạn nộp: ${a.dueDate.day}/${a.dueDate.month}/${a.dueDate.year}',
                          style: TextStyle(
                            color: isOverdue ? Colors.red : null,
                          ),
                        ),
                        if (!isInstructor) ...[
                          if (hasSubmitted && submission != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              submission.grade != null 
                                  ? 'Điểm: ${submission.grade}/100'
                                  : 'Đã nộp - Chờ chấm',
                              style: TextStyle(
                                color: submission.grade != null ? Colors.blue : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (!isOverdue) ...[
                            Text(
                              daysLeft > 0 ? 'Còn $daysLeft ngày' : 'Hết hạn hôm nay',
                              style: TextStyle(
                                color: daysLeft > 3 ? Colors.green : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'Số bài nộp: ${a.submissions.length}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isInstructor 
                        ? null 
                        : ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubmitAssignmentScreen(
                                    courseId: course.id,
                                    assignment: a,
                                  ),
                                ),
                              );
                              // Refresh if submission was successful
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            },
                            child: Text(hasSubmitted ? 'Xem/Nộp lại' : 'Nộp bài'),
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _quizzesTab(Course course) {
    final userId = _authService.currentUser?.uid ?? '';
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserData(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final userData = userSnapshot.data;
        final userRole = userData?['role'] ?? 'student';
        final isInstructor = userRole == 'instructor';
        
        return StreamBuilder<List<Quiz>>(
          stream: _firestoreService.getCourseQuizzesStream(course.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final quizzes = snapshot.data!;
            if (quizzes.isEmpty) return const Center(child: Text('Chưa có quiz'));
            
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final q = quizzes[index];
                final now = DateTime.now();
                final isOverdue = now.isAfter(q.dueDate);
                
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.quiz,
                      color: isOverdue ? Colors.red : Colors.blue,
                    ),
                    title: Text(q.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (q.description.isNotEmpty) ...[
                          Text(q.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                        ],
                        Text('Câu hỏi: ${q.questions.length} - Tổng điểm: ${q.getTotalPoints()}'),
                        Text(
                          'Hạn: ${q.dueDate.day}/${q.dueDate.month}/${q.dueDate.year}',
                          style: TextStyle(
                            color: isOverdue ? Colors.red : null,
                            fontSize: 12,
                          ),
                        ),
                        if (isInstructor) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Bạn là giảng viên - Không thể làm quiz',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isInstructor 
                        ? null 
                        : ElevatedButton(
                            onPressed: isOverdue 
                                ? null 
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QuizTakeScreen(
                                          courseId: course.id, 
                                          quiz: q,
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(isOverdue ? 'Hết hạn' : 'Làm bài'),
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _discussionTab(Course course) {
    return CourseDiscussionScreen(course: course);
  }
}
