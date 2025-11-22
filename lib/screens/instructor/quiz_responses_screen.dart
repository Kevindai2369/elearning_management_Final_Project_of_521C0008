import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Responses: ${widget.quiz.title}')),
      body: StreamBuilder<Quiz?>(
        stream: _firestore.getQuizStream(widget.courseId, widget.quiz.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final quiz = snapshot.data!;

          // responses stored as map keyed by studentId
          final raw = quiz.toMap();
          final responsesObj = raw['responses'];

          if (responsesObj == null || responsesObj is! Map) {
            return const Center(child: Text('Chưa có phản hồi')); 
          }

          final entries = Map<String, dynamic>.from(responsesObj).entries.toList();

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
                      Text('Student: $studentId', style: const TextStyle(fontWeight: FontWeight.bold)),
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
