import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final List<dynamic> answers;
  final double score;

  const QuizResultScreen({super.key, required this.quiz, required this.answers, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điểm: ${score.toStringAsFixed(1)} / ${quiz.getTotalPoints().toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: quiz.questions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final q = quiz.questions[index];
                  final ans = index < answers.length ? answers[index] : null;
                  final isMcq = q.type == 'multiple_choice';
                  final bool correct = isMcq && ans is int && ans == q.correctAnswer;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Câu ${index + 1}. ${q.question}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (isMcq) ...[
                            Text('Câu trả lời của bạn: ${ans is int ? (ans >=0 && ans < q.options.length ? q.options[ans] : 'Không trả lời') : 'Không trả lời'}'),
                            const SizedBox(height: 6),
                            Text('Đáp án đúng: ${q.correctAnswer >=0 && q.correctAnswer < q.options.length ? q.options[q.correctAnswer] : 'Không có'}'),
                            const SizedBox(height: 6),
                            Text(correct ? 'Đúng (+${q.points})' : 'Sai (0)'),
                          ] else ...[
                            Text('Câu trả lời của bạn:'),
                            const SizedBox(height: 6),
                            Text(ans is String ? ans : 'Chưa trả lời'),
                            const SizedBox(height: 8),
                            const Text('Phần này sẽ được chấm thủ công.'),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại khóa học'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
