import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/quiz_model.dart';

class QuizResponsesScreen extends StatefulWidget {
  final String courseId;
  final Quiz quiz;

  const QuizResponsesScreen({super.key, required this.courseId, required this.quiz});

  @override
  State<QuizResponsesScreen> createState() => _QuizResponsesScreenState();
}

class _QuizResponsesScreenState extends State<QuizResponsesScreen> {
  final _firestore = FirestoreService();
  final _authService = AuthService();
  final Map<String, String> _studentNames = {}; // Cache student names

  Future<String> _getStudentName(String studentId) async {
    if (_studentNames.containsKey(studentId)) {
      return _studentNames[studentId]!;
    }
    
    final userData = await _authService.getUserData(studentId);
    final name = userData?['fullName'] ?? studentId;
    _studentNames[studentId] = name;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Responses: ${widget.quiz.title}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('quizzes')
            .doc(widget.quiz.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Quiz không tồn tại'));
          }

          // Get raw data from Firestore document
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final responsesObj = data['responses'];

          // Debug: print raw data
          debugPrint('Quiz responses raw data: $responsesObj');
          debugPrint('Quiz responses type: ${responsesObj.runtimeType}');

          if (responsesObj == null || responsesObj is! Map) {
            return const Center(child: Text('Chưa có phản hồi')); 
          }

          final entries = Map<String, dynamic>.from(responsesObj).entries.toList();
          
          if (entries.isEmpty) {
            return const Center(child: Text('Chưa có phản hồi'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              final studentId = e.key;
              final map = Map<String, dynamic>.from(e.value as Map);

              final answers = List<dynamic>.from(map['answers'] ?? []);
              final score = (map['score'] ?? 0).toDouble();
              final submittedAt = map['submittedAt'] != null ? DateTime.parse(map['submittedAt'] as String) : null;
              final feedback = map['feedback'] as String?;

              final gradeController = TextEditingController(text: score.toString());
              final feedbackController = TextEditingController(text: feedback ?? '');

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getStudentName(studentId),
                        builder: (context, snapshot) {
                          final name = snapshot.data ?? studentId;
                          return Text('Sinh viên: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                        },
                      ),
                      const SizedBox(height: 6),
                      Text('Submitted: ${submittedAt?.toLocal().toString() ?? 'Unknown'}'),
                      const SizedBox(height: 6),
                      Text('Answers:'),
                      ...List.generate(widget.quiz.questions.length, (qi) {
                        final q = widget.quiz.questions[qi];
                        final a = qi < answers.length ? answers[qi] : null;
                        if (q.type == 'multiple_choice') {
                          final text = (a is int && a >= 0 && a < q.options.length) ? q.options[a] : 'Không trả lời';
                          final correct = (a is int && a == q.correctAnswer);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('Câu ${qi+1}: $text${correct ? ' (Đúng)' : ' (Sai)'}'),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Câu ${qi+1}: (Short answer)'),
                                const SizedBox(height: 4),
                                Text(a is String ? a : 'Chưa trả lời'),
                              ],
                            ),
                          );
                        }
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: gradeController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Điểm (0-100)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final text = gradeController.text.trim();
                              final parsed = double.tryParse(text);
                              if (parsed == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm không hợp lệ')));
                                return;
                              }
                              double clamped = parsed;
                              if (clamped < 0) clamped = 0;
                              if (clamped > 100) clamped = 100;
                              await _firestore.gradeQuizResponse(widget.courseId, widget.quiz.id, studentId, clamped, feedbackController.text.trim());
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu điểm và phản hồi')));
                            },
                            child: const Text('Lưu'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: feedbackController,
                        decoration: const InputDecoration(labelText: 'Phản hồi'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
