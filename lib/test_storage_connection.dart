import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

/// Simple test screen to verify Firebase Storage connection
class TestStorageScreen extends StatefulWidget {
  const TestStorageScreen({super.key});

  @override
  State<TestStorageScreen> createState() => _TestStorageScreenState();
}

class _TestStorageScreenState extends State<TestStorageScreen> {
  String _status = 'Chưa test';
  bool _isLoading = false;

  Future<void> _testStorageConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang kiểm tra...';
    });

    try {
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = '❌ LỖI: Chưa đăng nhập!\nVui lòng đăng nhập trước.';
          _isLoading = false;
        });
        return;
      }

      debugPrint('=== TEST STORAGE CONNECTION ===');
      debugPrint('User ID: ${user.uid}');
      debugPrint('User Email: ${user.email}');

      // Get storage instance
      final storage = FirebaseStorage.instance;
      debugPrint('Storage instance created');
      debugPrint('Bucket: ${storage.bucket}');

      // Create a test file
      final testData = Uint8List.fromList('Test upload from Flutter'.codeUnits);
      final testPath = 'test/${user.uid}/test_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      debugPrint('Test path: $testPath');
      debugPrint('Test data size: ${testData.length} bytes');

      // Try to upload
      final ref = storage.ref().child(testPath);
      debugPrint('Reference created: ${ref.fullPath}');

      setState(() => _status = 'Đang upload test file...');

      final uploadTask = ref.putData(
        testData,
        SettableMetadata(contentType: 'text/plain'),
      );

      // Monitor progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      await uploadTask;
      debugPrint('Upload completed');

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Download URL: $downloadUrl');

      // Try to delete test file
      await ref.delete();
      debugPrint('Test file deleted');

      setState(() {
        _status = '✅ THÀNH CÔNG!\n\n'
            'Firebase Storage hoạt động bình thường.\n'
            'User: ${user.email}\n'
            'Bucket: ${storage.bucket}\n'
            'Test path: $testPath\n\n'
            'Bạn có thể upload file bình thường.';
        _isLoading = false;
      });

      debugPrint('=== TEST STORAGE SUCCESS ===');
    } on FirebaseException catch (e) {
      debugPrint('=== TEST STORAGE FIREBASE ERROR ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      
      String errorMsg = '❌ LỖI FIREBASE:\n\n';
      
      if (e.code == 'storage/unauthorized') {
        errorMsg += 'Không có quyền truy cập Storage.\n\n'
            'Nguyên nhân:\n'
            '- Storage Rules chưa đúng\n'
            '- Chưa enable Storage trên Firebase Console\n\n'
            'Giải pháp:\n'
            '1. Vào Firebase Console\n'
            '2. Storage > Rules\n'
            '3. Đảm bảo rules cho phép authenticated users';
      } else if (e.code == 'storage/unknown') {
        errorMsg += 'Lỗi không xác định.\n\n'
            'Nguyên nhân:\n'
            '- Storage chưa được enable\n'
            '- Bucket không tồn tại\n'
            '- Network issue\n\n'
            'Giải pháp:\n'
            '1. Kiểm tra Firebase Console > Storage\n'
            '2. Enable Storage nếu chưa có\n'
            '3. Kiểm tra internet connection';
      } else {
        errorMsg += 'Code: ${e.code}\n'
            'Message: ${e.message}';
      }

      setState(() {
        _status = errorMsg;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('=== TEST STORAGE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _status = '❌ LỖI:\n\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Storage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kiểm Tra Kết Nối Firebase Storage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testStorageConnection,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Chạy Test',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Test này sẽ:\n'
                  '1. Kiểm tra đăng nhập\n'
                  '2. Thử upload file nhỏ\n'
                  '3. Lấy download URL\n'
                  '4. Xóa file test\n\n'
                  'Xem Debug Console để biết chi tiết.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
