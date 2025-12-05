import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import 'submissions_screen.dart';
import 'quiz_responses_screen.dart';
import 'create_quiz_screen.dart';
import 'create_assignment_screen.dart';
import 'upload_material_screen.dart';
import 'manage_students_screen.dart';
import 'course_analytics_screen.dart';

class InstructorCourseManagementScreen extends StatelessWidget {
  final Course course;

  const InstructorCourseManagementScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
  final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý ${course.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseAnalyticsScreen(
                    courseId: course.id,
                    courseName: course.name,
                  ),
                ),
              );
            },
            tooltip: 'Thống Kê',
          ),
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/course/${course.id}',
                arguments: course,
              );
            },
            tooltip: 'Xem Khóa Học',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMenu(context);
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Students Section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sinh Viên (${course.studentIds.length})', 
                    style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageStudentsScreen(course: course),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Quản Lý'),
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text('${course.studentIds.length} sinh viên'),
                subtitle: const Text('Xem danh sách và quản lý sinh viên'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageStudentsScreen(course: course),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Quizzes Section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quizzes', style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateQuizScreen(courseId: course.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Quiz'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: StreamBuilder<List<Quiz>>(
                stream: firestore.getCourseQuizzesStream(course.id),
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final quizzes = snap.data!;
                  if (quizzes.isEmpty) return const Center(child: Text('Chưa có quiz'));
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: quizzes.length,
                    itemBuilder: (context, i) {
                      final q = quizzes[i];
                      return SizedBox(
                        width: 300,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Câu hỏi: ${q.questions.length} - Điểm: ${q.getTotalPoints()}'),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => QuizResponsesScreen(courseId: course.id, quiz: q)));
                                  },
                                  child: const Text('Xem phản hồi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Assignments Section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Assignments', style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateAssignmentScreen(courseId: course.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Bài Tập'),
                  ),
                ],
              ),
            ),

            StreamBuilder<List<Assignment>>(
              stream: firestore.getCourseAssignmentsStream(course.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final assignments = snapshot.data!;
                if (assignments.isEmpty) return const Center(child: Text('Chưa có bài tập'));
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final a = assignments[index];
                    return Card(
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Text('Hạn nộp: ${a.dueDate.toLocal()}'),
                        trailing: ElevatedButton(
                          child: const Text('Xem Nộp Bài'),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SubmissionsScreen(courseId: course.id, assignmentId: a.id, assignmentTitle: a.title)));
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Tạo Quiz'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateQuizScreen(courseId: course.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Tạo Bài Tập'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateAssignmentScreen(courseId: course.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Tài Liệu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadMaterialScreen(courseId: course.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Quản Lý Sinh Viên'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageStudentsScreen(course: course),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import Học Sinh (CSV)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/import-csv',
                  arguments: {'courseId': course.id},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
