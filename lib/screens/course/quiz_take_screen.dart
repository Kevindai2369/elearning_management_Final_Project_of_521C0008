import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'quiz_result_screen.dart';
import 'dart:async';

class QuizTakeScreen extends StatefulWidget {
  final String courseId;
  final Quiz quiz;

  const QuizTakeScreen({super.key, required this.courseId, required this.quiz});

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  final _firestore = FirestoreService();
  final _auth = AuthService();

  late List<dynamic> _selectedAnswers; // store chosen option index (int) for MCQ or String for short answer; -1 = unanswered
  bool _submitting = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    // initialize selected answers: for MCQ -> -1; for short answer -> ''
    _selectedAnswers = List<dynamic>.generate(widget.quiz.questions.length, (i) => widget.quiz.questions[i].type == 'multiple_choice' ? -1 : '');

    // initialize timer: use quiz.duration (minutes) but don't exceed time until dueDate
    final now = DateTime.now();
    final durationSeconds = widget.quiz.duration * 60;
    final untilDue = widget.quiz.dueDate.difference(now).inSeconds;
    _remainingSeconds = durationSeconds;
    if (untilDue > 0 && untilDue < _remainingSeconds) {
      _remainingSeconds = untilDue;
    }
    if (_remainingSeconds <= 0) {
      _timeUp = true;
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _remainingSeconds -= 1;
          if (_remainingSeconds <= 0) {
            _timeUp = true;
            _timer?.cancel();
          }
        });
      });
    }
  }

  double _computeAutoScore() {
    double total = 0.0;
    for (var i = 0; i < widget.quiz.questions.length; i++) {
      final q = widget.quiz.questions[i];
      if (q.type == 'multiple_choice') {
        final sel = _selectedAnswers[i] as int? ?? -1;
        if (sel >= 0 && sel == q.correctAnswer) total += q.points;
      }
      // short_answer not auto-graded here
    }
    return total;
  }

  Future<void> _submit() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập trước khi làm quiz')));
      return;
    }

    // Prevent submission if time up or past dueDate
    if (_timeUp || DateTime.now().isAfter(widget.quiz.dueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hết thời gian. Không thể nộp bài.')));
      return;
    }

    final score = _computeAutoScore();
    final answersToStore = List<dynamic>.from(_selectedAnswers);

    setState(() => _submitting = true);

    try {
      final response = {
        'quizId': widget.quiz.id,
        'studentId': user.uid,
        'answers': answersToStore,
        'score': score,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      await _firestore.submitQuizResponse(widget.courseId, widget.quiz.id, response);

      if (!mounted) return;
      // show results screen with per-question feedback
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QuizResultScreen(quiz: widget.quiz, answers: answersToStore, score: score)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi nộp quiz: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: widget.quiz.questions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final q = widget.quiz.questions[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Câu ${index + 1}. ${q.question}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (q.type == 'multiple_choice') ...[
                          for (var optIndex = 0; optIndex < q.options.length; optIndex++)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[index] = optIndex;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedAnswers[index] == optIndex
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _selectedAnswers[index] == optIndex
                                      ? Colors.blue.shade50
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: optIndex,
                                      groupValue: _selectedAnswers[index] as int?,
                                      onChanged: (v) {
                                        setState(() {
                                          _selectedAnswers[index] = v ?? -1;
                                        });
                                      },
                                    ),
                                    Expanded(child: Text(q.options[optIndex])),
                                  ],
                                ),
                              ),
                            ),
                        ] else ...[
                          TextField(
                            onChanged: (text) {
                              _selectedAnswers[index] = text;
                            },
                            decoration: const InputDecoration(hintText: 'Ghi câu trả lời ngắn...'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text('Điểm: ${q.points}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng điểm tự chấm: ${_computeAutoScore().toStringAsFixed(1)} / ${widget.quiz.getTotalPoints().toStringAsFixed(1)}'),
                      const SizedBox(height: 6),
                      Text(_timeUp ? 'Hết thời gian' : 'Thời gian còn lại: ${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: (_submitting || _timeUp) ? null : _submit,
                  child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Nộp bài'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
