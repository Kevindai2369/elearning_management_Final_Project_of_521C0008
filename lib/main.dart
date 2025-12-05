import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/course.dart';
import 'screens/student/browse_courses_screen.dart';
import 'screens/student/favorite_courses_screen.dart';
import 'screens/course/course_detail_screen.dart';
import 'screens/instructor/create_course_screen.dart';
import 'screens/instructor/upload_material_screen.dart';
import 'screens/instructor/import_csv_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/instructor/instructor_course_management_screen.dart';

// --- MAIN ENTRY POINT ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Use debugPrint to avoid printing in production
    // and to be consistent with analyzer recommendations.
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const ELearningApp());
}

class ELearningApp extends StatelessWidget {
  const ELearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IT Faculty E-Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen(); // Route based on role
          } else {
            return const LoginScreen();
          }
        },
      ),
      onGenerateRoute: (settings) {
        // simple route wiring: /browse, /create-course, /upload-material?courseId=, /import-csv?courseId=
        if (settings.name == '/browse') {
          return MaterialPageRoute(builder: (_) => const BrowseCoursesScreen());
        }
        if (settings.name == '/favorite-courses') {
          return MaterialPageRoute(builder: (_) => const FavoriteCoursesScreen());
        }
        if (settings.name == '/edit-profile') {
          return MaterialPageRoute(builder: (_) => const EditProfileScreen());
        }
        if (settings.name == '/create-course') {
          return MaterialPageRoute(builder: (_) => const CreateCourseScreen());
        }
        if (settings.name?.startsWith('/course/') == true) {
          // route was created using pushNamed('/course/<id>', arguments: Course)
          final arg = settings.arguments;
          if (arg is Course) {
            return MaterialPageRoute(builder: (_) => CourseDetailScreen(course: arg));
          }
        }
        if (settings.name == '/upload-material') {
          final args = settings.arguments as Map<String, dynamic>?;
          final courseId = args?['courseId'] as String?;
          if (courseId != null) return MaterialPageRoute(builder: (_) => UploadMaterialScreen(courseId: courseId));
        }
        if (settings.name == '/import-csv') {
          final args = settings.arguments as Map<String, dynamic>?;
          final courseId = args?['courseId'] as String?;
          if (courseId != null) return MaterialPageRoute(builder: (_) => ImportCSVScreen(courseId: courseId));
        }
        return null;
      },
    );
  }
}

// --- HOME SCREEN (Route based on user role) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUser?.uid ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data;
        final role = userData?['role'] ?? 'student';

        if (role == 'instructor') {
          return const InstructorDashboard();
        } else {
          return const StudentDashboard();
        }
      },
    );
  }
}

// --- STUDENT DASHBOARD ---
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';
    final userEmail = _authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khóa Học Của Tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildStudentDrawer(),
      body: StreamBuilder<List<Course>>(
        stream: _firestoreService.getStudentCoursesStream(userId, userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa tham gia khóa học nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/browse');
                    },
                    child: const Text('Duyệt Khóa Học'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(context, course);
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentDrawer() {
    final userId = _authService.currentUser?.uid ?? '';
    
    return Drawer(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.getUserStream(userId),
        builder: (context, snapshot) {
          // Debug logging
          debugPrint('Student Drawer - Connection: ${snapshot.connectionState}');
          debugPrint('Student Drawer - Has data: ${snapshot.hasData}');
          debugPrint('Student Drawer - Data: ${snapshot.data}');
          
          final userData = snapshot.data;
          final email = userData?['email'] ?? 'unknown@example.com';
          final fullName = userData?['fullName'] ?? 'User';
          final avatarUrl = userData?['avatarUrl'] as String?;
          final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
          
          debugPrint('Student Drawer - Avatar URL: $avatarUrl');
          debugPrint('Student Drawer - Has Avatar: $hasAvatar');

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        key: ValueKey('student-avatar-$avatarUrl'),
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: hasAvatar
                            ? ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  cacheWidth: 140,
                                  cacheHeight: 140,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 28, color: Colors.blue),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 28, color: Colors.blue),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Khóa Học Của Tôi'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text('Khóa Học Yêu Thích'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/favorite-courses');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Chỉnh Sửa Hồ Sơ'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng Xuất'),
                onTap: _logout,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/course/${course.id}', arguments: course);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: course.getColor(), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Giảng viên: ${course.instructorName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Học sinh: ${course.studentIds.length}'),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/course/${course.id}', arguments: course);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Vào Học'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất')),
      );
    }
  }
}

// --- INSTRUCTOR DASHBOARD ---
class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khóa Học Của Tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildInstructorDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-course');
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Course>>(
        stream: _firestoreService.getInstructorCoursesStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa tạo khóa học nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildInstructorCourseCard(context, course);
            },
          );
        },
      ),
    );
  }

  Widget _buildInstructorDrawer() {
    final userId = _authService.currentUser?.uid ?? '';
    
    return Drawer(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.getUserStream(userId),
        builder: (context, snapshot) {
          // Debug logging
          debugPrint('Instructor Drawer - Connection: ${snapshot.connectionState}');
          debugPrint('Instructor Drawer - Has data: ${snapshot.hasData}');
          debugPrint('Instructor Drawer - Data: ${snapshot.data}');
          
          final userData = snapshot.data;
          final email = userData?['email'] ?? 'unknown@example.com';
          final fullName = userData?['fullName'] ?? 'User';
          final avatarUrl = userData?['avatarUrl'] as String?;
          final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
          
          debugPrint('Instructor Drawer - Avatar URL: $avatarUrl');
          debugPrint('Instructor Drawer - Has Avatar: $hasAvatar');

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        key: ValueKey('instructor-avatar-$avatarUrl'),
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: hasAvatar
                            ? ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  cacheWidth: 140,
                                  cacheHeight: 140,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 28, color: Colors.orange),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 28, color: Colors.orange),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Khóa Học Của Tôi'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Tạo Khóa Học Mới'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-course');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Chỉnh Sửa Hồ Sơ'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng Xuất'),
                onTap: _logout,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstructorCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InstructorCourseManagementScreen(course: course),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: course.getColor(), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        child: Text('Chỉnh sửa'),
                      ),
                      const PopupMenuItem(
                        child: Text('Xóa'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Học sinh: ${course.studentIds.length}'),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorCourseManagementScreen(course: course)));
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Quản Lý'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất')),
      );
    }
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late TabController _tabController;

  // Login fields
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // SignUp fields
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  final _signUpFullNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  UserRole? _selectedRole = UserRole.student;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _signUpFullNameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email hợp lệ (ví dụ: user@example.com)';
      });
      return;
    }

    if (_loginPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signIn(email, _loginPasswordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatFirebaseError(e.code);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    final email = _signUpEmailController.text.trim();
    final fullName = _signUpFullNameController.text.trim();
    final password = _signUpPasswordController.text;
    final confirmPassword = _signUpConfirmPasswordController.text;

    if (fullName.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập họ tên';
      });
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email hợp lệ (ví dụ: user@example.com)';
      });
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Mật khẩu nhập lại không khớp';
      });
      return;
    }

    if (_selectedRole == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn vai trò (Học sinh hoặc Giảng viên)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUp(
        email,
        password,
        fullName,
        _selectedRole!.value,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
        );
        // Reset and switch to login tab
        _signUpEmailController.clear();
        _signUpPasswordController.clear();
        _signUpConfirmPasswordController.clear();
        _signUpFullNameController.clear();
        _tabController.animateTo(0);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _formatFirebaseError(e.code);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email này chưa được đăng ký. Vui lòng đăng ký tài khoản mới.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng đăng nhập.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng dùng mật khẩu mạnh hơn.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      default:
  return 'Lỗi: $code. Vui lòng thử lại.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IT Faculty E-Learning'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginTab(),
          _buildSignUpTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đăng Nhập'),
            Tab(text: 'Đăng Ký'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            'Chào Mừng',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 40),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _loginEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'user@example.com',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPasswordController,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đăng Nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Chọn vai trò của bạn:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRole = UserRole.student;
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedRole == UserRole.student
                            ? Colors.blue
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Radio<UserRole>(
                          value: UserRole.student,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                              _errorMessage = null;
                            });
                          },
                        ),
                        const Text('Học sinh'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRole = UserRole.instructor;
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedRole == UserRole.instructor
                            ? Colors.blue
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Radio<UserRole>(
                          value: UserRole.instructor,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                              _errorMessage = null;
                            });
                          },
                        ),
                        const Text('Giảng viên'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _signUpFullNameController,
            decoration: const InputDecoration(
              labelText: 'Họ và Tên',
              hintText: 'Ví dụ: Nguyễn Văn A',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'user@example.com',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpPasswordController,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Tối thiểu 6 ký tự',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpConfirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Xác nhận mật khẩu',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đăng Ký'),
          ),
        ],
      ),
    );
  }
}
