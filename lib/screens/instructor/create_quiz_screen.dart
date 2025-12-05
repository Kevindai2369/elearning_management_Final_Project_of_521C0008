import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final String courseId;

  const CreateQuizScreen({super.key, required this.courseId});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  final List<_QuestionData> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add first question by default
    _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionData());
    });
  }

  void _deleteQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        _questions[index].dispose();
        _questions.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz phải có ít nhất 1 câu hỏi')),
      );
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate all questions
    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng hoàn thành câu hỏi ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService().currentUser?.uid ?? '';
      final questions = _questions.map((qd) => qd.toQuestion()).toList();

      final quizData = {
        'courseId': widget.courseId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'questions': questions.map((q) => q.toMap()).toList(),
        'duration': int.tryParse(_durationController.text) ?? 30,
        'dueDate': _dueDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': userId,
      };

      await FirestoreService().addQuiz(widget.courseId, quizData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo quiz thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Quiz Mới'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createQuiz,
              tooltip: 'Lưu Quiz',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề Quiz *',
                hintText: 'Ví dụ: Kiểm tra giữa kỳ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Mô tả về nội dung quiz...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Duration and Due Date
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian (phút) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nhập thời gian';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Số không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDueDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Hạn: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Questions header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu hỏi (${_questions.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm câu hỏi'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Questions list
            ..._questions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _QuestionCard(
                  key: ValueKey(entry.key),
                  index: entry.key,
                  questionData: entry.value,
                  onDelete: () => _deleteQuestion(entry.key),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Create button
            ElevatedButton(
              onPressed: _isLoading ? null : _createQuiz,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo Quiz', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// Question Data Class
class _QuestionData {
  final questionController = TextEditingController();
  final pointsController = TextEditingController(text: '1');
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int correctAnswer = 0;

  void dispose() {
    questionController.dispose();
    pointsController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
  }

  bool validate() {
    if (questionController.text.trim().isEmpty) return false;
    for (var controller in optionControllers) {
      if (controller.text.trim().isEmpty) return false;
    }
    return true;
  }

  Question toQuestion() {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: questionController.text.trim(),
      type: 'multiple_choice',
      options: optionControllers.map((c) => c.text.trim()).toList(),
      correctAnswer: correctAnswer,
      points: double.tryParse(pointsController.text) ?? 1.0,
    );
  }
}

// Question Card Widget
class _QuestionCard extends StatefulWidget {
  final int index;
  final _QuestionData questionData;
  final VoidCallback onDelete;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.questionData,
    required this.onDelete,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  @override
  Widget build(BuildContext context) {
    final qd = widget.questionData;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu ${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: qd.pointsController,
                        decoration: const InputDecoration(
                          labelText: 'Điểm',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text
            TextFormField(
              controller: qd.questionController,
              decoration: const InputDecoration(
                labelText: 'Câu hỏi *',
                hintText: 'Nhập nội dung câu hỏi...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            const Text(
              'Các đáp án (chọn đáp án đúng):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Options
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      qd.correctAnswer = i;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: qd.correctAnswer == i
                            ? Colors.green
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: qd.correctAnswer == i
                          ? Colors.green.shade50
                          : null,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              qd.correctAnswer = i;
                            });
                          },
                          child: Icon(
                            qd.correctAnswer == i
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: qd.correctAnswer == i
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: qd.optionControllers[i],
                            decoration: InputDecoration(
                              labelText: 'Đáp án ${String.fromCharCode(65 + i)}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
