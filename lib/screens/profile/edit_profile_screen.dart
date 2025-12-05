import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/file_handler_simple.dart';
import 'package:file_picker/file_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _fullNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  Uint8List? _selectedImageBytes;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.uid ?? '';
      final userData = await _authService.getUserData(userId);
      
      if (userData != null) {
        setState(() {
          _userData = userData;
          _fullNameController.text = userData['fullName'] ?? '';
          _avatarUrl = userData['avatarUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('=== PICK IMAGE START ===');
      final file = await SimpleFileHandler.pickFile(
        fileType: FileType.image,
      );

      debugPrint('File picked: ${file != null}');
      if (file != null) {
        debugPrint('File name: ${file.name}');
        debugPrint('File bytes: ${file.bytes.length}');
        setState(() {
          _selectedImageBytes = file.bytes;
        });
        debugPrint('=== PICK IMAGE SUCCESS ===');
      } else {
        debugPrint('=== PICK IMAGE CANCELLED ===');
      }
    } catch (e, stackTrace) {
      debugPrint('=== PICK IMAGE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    debugPrint('=== _uploadAvatar CALLED ===');
    
    if (_selectedImageBytes == null) {
      debugPrint('ERROR: _selectedImageBytes is null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ảnh trước'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isUploadingAvatar = true);
    debugPrint('Upload state set to true');
    
    try {
      final userId = _authService.currentUser?.uid ?? '';
      debugPrint('Current user: ${_authService.currentUser}');
      
      if (userId.isEmpty) {
        throw Exception('User ID is empty - user not logged in');
      }
      
      debugPrint('=== UPLOAD AVATAR START ===');
      debugPrint('User ID: $userId');
      debugPrint('Image size: ${_selectedImageBytes!.length} bytes');
      
      // Upload to Firebase Storage
      debugPrint('Calling uploadAvatar...');
      final downloadUrl = await _storageService.uploadAvatar(
        userId: userId,
        imageBytes: _selectedImageBytes!,
      );
      debugPrint('uploadAvatar returned: $downloadUrl');
      
      if (downloadUrl.isEmpty) {
        throw Exception('Download URL is empty - upload may have failed');
      }
      
      debugPrint('Download URL: $downloadUrl');

      // Clear image cache for old avatar
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        try {
          debugPrint('Evicting old avatar cache: $_avatarUrl');
          await NetworkImage(_avatarUrl!).evict();
        } catch (e) {
          debugPrint('Cache eviction error: $e');
        }
      }

      // Update Firestore
      debugPrint('Updating Firestore with new avatar URL...');
      await _firestoreService.setDoc(
        'users',
        userId,
        {'avatarUrl': downloadUrl},
        merge: true,
      );
      
      debugPrint('Firestore updated successfully');
      
      // Verify the update
      final updatedData = await _authService.getUserData(userId);
      debugPrint('Verified avatar URL in Firestore: ${updatedData?['avatarUrl']}');

      setState(() {
        _avatarUrl = downloadUrl;
        _selectedImageBytes = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện'),
            backgroundColor: Colors.green,
          ),
        );
        // Wait a bit for Firestore to propagate
        debugPrint('Waiting for Firestore to propagate...');
        await Future.delayed(const Duration(milliseconds: 800));
        debugPrint('=== UPLOAD AVATAR COMPLETE ===');
        // Notify parent that profile was updated
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('=== UPLOAD AVATAR ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ tên')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.uid ?? '';
      
      await _firestoreService.setDoc(
        'users',
        userId,
        {'fullName': fullName},
        merge: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _userData?['role'] ?? 'student';
    final email = _userData?['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Hồ Sơ'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              'Lưu',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar section
            Center(
              child: Stack(
                children: [
                  // Avatar display
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _selectedImageBytes != null
                        ? MemoryImage(_selectedImageBytes!)
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!)
                            : null) as ImageProvider?,
                    child: (_avatarUrl == null || _avatarUrl!.isEmpty) &&
                            _selectedImageBytes == null
                        ? Text(
                            _fullNameController.text.isNotEmpty
                                ? _fullNameController.text[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  
                  // Edit button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: _isUploadingAvatar ? null : _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload button (if image selected)
            if (_selectedImageBytes != null)
              ElevatedButton.icon(
                onPressed: _isUploadingAvatar ? null : _uploadAvatar,
                icon: _isUploadingAvatar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploadingAvatar ? 'Đang tải...' : 'Tải lên ảnh'),
              ),
            
            const SizedBox(height: 32),
            
            // Email (read-only)
            TextField(
              controller: TextEditingController(text: email),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            
            const SizedBox(height: 16),
            
            // Role (read-only)
            TextField(
              controller: TextEditingController(
                text: role == 'instructor' ? 'Giảng viên' : 'Học sinh',
              ),
              decoration: const InputDecoration(
                labelText: 'Vai trò',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            
            const SizedBox(height: 16),
            
            // Full name (editable)
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu Thay Đổi',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
