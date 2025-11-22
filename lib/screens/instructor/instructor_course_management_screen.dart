import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../models/assignment_model.dart';
import '../../models/quiz_model.dart';
import 'submissions_screen.dart';
import 'quiz_responses_screen.dart';

class InstructorCourseManagementScreen extends StatelessWidget {
  final Course course;

  const InstructorCourseManagementScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
  final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý ${course.name}')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Quizzes', style: Theme.of(context).textTheme.titleLarge),
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

            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Assignments', style: Theme.of(context).textTheme.titleLarge),
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
}
