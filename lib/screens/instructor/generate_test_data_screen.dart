import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/test_data_generator.dart';
import '../../widgets/common/app_snackbar.dart';

class GenerateTestDataScreen extends StatefulWidget {
  const GenerateTestDataScreen({super.key});

  @override
  State<GenerateTestDataScreen> createState() => _GenerateTestDataScreenState();
}

class _GenerateTestDataScreenState extends State<GenerateTestDataScreen> {
  final AuthService _authService = AuthService();
  final TestDataGenerator _generator = TestDataGenerator();
  bool _isGenerating = false;
  String _log = '';

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
  }

  Future<void> _generateData() async {
    setState(() {
      _isGenerating = true;
      _log = '';
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        _addLog('❌ Lỗi: Không tìm thấy user ID');
        return;
      }

      // Set up logging callback
      _generator.onLog = (message) {
        _addLog(message);
      };
      
      // Generate test data
      await _generator.quickTest(userId);
      
      if (mounted) {
        AppSnackbar.success(context, 'Tạo dữ liệu test thành công!');
      }
    } catch (e) {
      _addLog('\n❌ Lỗi: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Lỗi: $e');
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Dữ Liệu Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Hướng Dẫn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tool này sẽ tạo dữ liệu mẫu cho khóa học đầu tiên của bạn:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('📝 3 Assignments'),
                    _buildInfoItem('📋 2 Quizzes'),
                    _buildInfoItem('📤 Submissions với điểm ngẫu nhiên'),
                    _buildInfoItem('🎯 Quiz attempts với điểm ngẫu nhiên'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, 
                            color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Lưu ý: Khóa học phải có học sinh trước khi tạo dữ liệu!',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateData,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isGenerating ? 'Đang tạo...' : 'Tạo Dữ Liệu Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            if (_log.isNotEmpty) ...[
              const Text(
                'Log:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _log,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
