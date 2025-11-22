import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../models/assignment_model.dart';

class SubmissionsScreen extends StatefulWidget {
  final String courseId;
  final String assignmentId;
  final String assignmentTitle;

  const SubmissionsScreen({super.key, required this.courseId, required this.assignmentId, required this.assignmentTitle});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nộp bài: ${widget.assignmentTitle}')),
      body: StreamBuilder<Assignment?>(
        stream: _firestore.getAssignmentStream(widget.courseId, widget.assignmentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final assignment = snapshot.data!;
          final subs = assignment.submissions;
          if (subs.isEmpty) return const Center(child: Text('Chưa có nộp bài'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: subs.length,
            itemBuilder: (context, index) {
              final s = subs[index];
              final gradeController = TextEditingController(text: s.grade?.toString() ?? '');
              final feedbackController = TextEditingController(text: s.feedback ?? '');
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('File: ${s.fileName}'),
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(s.fileUrl);
                          if (uri != null) {
                            // prefer launch in external application
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              // fallback: show link
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Link'), content: SelectableText(s.fileUrl), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))]));
                            }
                          } else {
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Link'), content: SelectableText(s.fileUrl), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))]));
                          }
                        },
                        child: const Text('Mở file'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: gradeController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Điểm'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final text = gradeController.text.trim();
                                  final g = double.tryParse(text);
                                  if (g == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm không hợp lệ')));
                                    return;
                                  }
                                  // enforce bounds 0 - 100
                                  double clamped = g;
                                  if (clamped < 0) clamped = 0;
                                  if (clamped > 100) clamped = 100;
                                    await _firestore.gradeSubmission(widget.courseId, widget.assignmentId, s.studentId, clamped, feedbackController.text.trim());
                                    if (!mounted) return;
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu điểm')));
                                    if (clamped != g) {
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm đã được điều chỉnh vào khoảng 0-100')));
                                    }
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
