import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

/// Test button to verify Storage connection
class TestStorageButton extends StatelessWidget {
  const TestStorageButton({super.key});

  Future<void> _testStorage(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      debugPrint('=== TESTING STORAGE ===');
      
      // Check auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      debugPrint('✅ User: ${user.email}');
      
      // Check storage instance
      final storage = FirebaseStorage.instance;
      debugPrint('✅ Storage instance created');
      debugPrint('   Bucket: ${storage.bucket}');
      
      // Try to create a reference
      final ref = storage.ref().child('_test/${DateTime.now().millisecondsSinceEpoch}.txt');
      debugPrint('✅ Reference created');
      debugPrint('   Path: ${ref.fullPath}');
      debugPrint('   Bucket: ${ref.bucket}');
      
      // Try to upload
      final testData = Uint8List.fromList('Test'.codeUnits);
      debugPrint('📤 Uploading test file...');
      
      final uploadTask = ref.putData(
        testData,
        SettableMetadata(contentType: 'text/plain'),
      );
      
      final snapshot = await uploadTask;
      debugPrint('✅ Upload completed');
      debugPrint('   State: ${snapshot.state}');
      
      // Try to get download URL
      final url = await ref.getDownloadURL();
      debugPrint('✅ Download URL: $url');
      
      // Clean up
      await ref.delete();
      debugPrint('✅ Test file deleted');
      
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Storage test PASSED!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      debugPrint('=== STORAGE TEST PASSED ===');
      
    } on FirebaseException catch (e) {
      debugPrint('=== STORAGE TEST FAILED ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Plugin: ${e.plugin}');
      
      String errorMsg = '';
      if (e.code == 'storage/unknown') {
        errorMsg = '❌ Storage chưa được enable.\n'
                   'Vào Firebase Console > Storage > Get Started';
      } else if (e.code == 'storage/unauthorized') {
        errorMsg = '❌ Không có quyền.\n'
                   'Chạy: firebase deploy --only storage';
      } else {
        errorMsg = '❌ ${e.code}: ${e.message}';
      }
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
    } catch (e) {
      debugPrint('=== STORAGE TEST ERROR ===');
      debugPrint('Error: $e');
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _testStorage(context),
      icon: const Icon(Icons.bug_report),
      label: const Text('Test Storage'),
      backgroundColor: Colors.orange,
    );
  }
}
