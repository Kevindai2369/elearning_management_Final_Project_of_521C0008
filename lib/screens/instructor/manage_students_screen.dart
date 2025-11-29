import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  final Course course;

  const ManageStudentsScreen({super.key, required this.course});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      // Reload course from Firestore to get latest studentIds
      final latestCourse = await _firestoreService.getCourse(widget.course.id);
      if (latestCourse == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy khóa học')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      final students = <Map<String, dynamic>>[];
      final studentIdsToUpdate = <String, String>{}; // email -> uid mapping
      
      for (final studentId in latestCourse.studentIds) {
        // Check if it's email or UID
        if (studentId.contains('@')) {
          // It's an email, try to find the user
          final userData = await _authService.getUserByEmail(studentId);
          if (userData != null) {
            // User found! Use their UID
            final uid = userData['uid'] as String;
            students.add({
              'id': uid,
              'email': userData['email'] ?? studentId,
              'fullName': userData['fullName'] ?? 'Unknown',
              'isEmail': false,
              'isRegistered': true,
            });
            // Mark for update in Firestore
            studentIdsToUpdate[studentId] = uid;
          } else {
            // User not found yet
            students.add({
              'id': studentId,
              'email': studentId,
              'fullName': 'Chưa đăng ký',
              'isEmail': true,
              'isRegistered': false,
            });
          }
        } else {
          // It's a UID, fetch user data
          final userData = await _authService.getUserData(studentId);
          if (userData != null) {
            students.add({
              'id': studentId,
              'email': userData['email'] ?? '',
              'fullName': userData['fullName'] ?? 'Unknown',
              'isEmail': false,
              'isRegistered': true,
            });
          }
        }
      }
      
      // Update course studentIds if we found any registered users
      if (studentIdsToUpdate.isNotEmpty) {
        await _updateStudentIds(studentIdsToUpdate);
      }
      
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudentIds(Map<String, String> emailToUidMap) async {
    try {
      // Get current studentIds
      final updatedStudentIds = List<String>.from(widget.course.studentIds);
      
      // Replace emails with UIDs
      for (var i = 0; i < updatedStudentIds.length; i++) {
        final studentId = updatedStudentIds[i];
        if (emailToUidMap.containsKey(studentId)) {
          updatedStudentIds[i] = emailToUidMap[studentId]!;
        }
      }
      
      // Update in Firestore
      await _firestoreService.updateCourse(widget.course.id, {
        'studentIds': updatedStudentIds,
      });
    } catch (e) {
      debugPrint('Error updating student IDs: $e');
    }
  }

  Future<void> _addStudentByEmail() async {
    final emailController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Sinh Viên'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email sinh viên',
            hintText: 'student@example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                Navigator.pop(context, email);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email không hợp lệ')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _firestoreService.enrollStudentInCourse(widget.course.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm sinh viên')),
          );
          _loadStudents(); // Reload list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeStudent(String studentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa sinh viên này khỏi khóa học?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.unenrollStudentFromCourse(
          widget.course.id,
          studentId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa sinh viên')),
          );
          _loadStudents(); // Reload list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Sinh Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStudentByEmail,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm Sinh Viên'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có sinh viên',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addStudentByEmail,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Thêm Sinh Viên'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/import-csv',
                            arguments: {'courseId': widget.course.id},
                          );
                          // Reload if import was successful
                          if (result == true && mounted) {
                            _loadStudents();
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import CSV'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header with count
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng: ${_students.length} sinh viên',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/import-csv',
                                arguments: {'courseId': widget.course.id},
                              );
                              // Reload if import was successful
                              if (result == true && mounted) {
                                _loadStudents();
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import CSV'),
                          ),
                        ],
                      ),
                    ),
                    // Student list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final isRegistered = student['isRegistered'] as bool? ?? true;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isRegistered
                                    ? Colors.blue.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  isRegistered ? Icons.person : Icons.email,
                                  color: isRegistered
                                      ? Colors.blue.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                              title: Text(
                                student['fullName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student['email'] ?? ''),
                                  if (!isRegistered)
                                    const Text(
                                      'Chưa đăng ký tài khoản',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeStudent(student['id']),
                                tooltip: 'Xóa khỏi khóa học',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
