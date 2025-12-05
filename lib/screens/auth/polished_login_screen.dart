import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_snackbar.dart';

class PolishedLoginScreen extends StatefulWidget {
  const PolishedLoginScreen({super.key});

  @override
  State<PolishedLoginScreen> createState() => _PolishedLoginScreenState();
}

class _PolishedLoginScreenState extends State<PolishedLoginScreen>
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
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  UserRole? _selectedRole = UserRole.student;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _errorMessage = null;
      });
    });
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
        AppSnackbar.success(context, 'Đăng nhập thành công!');
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
        AppSnackbar.success(
          context,
          'Đăng ký thành công! Vui lòng đăng nhập.',
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo/title
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.elevatedShadow,
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 48,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  const Text(
                    'IT Faculty E-Learning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  const Text(
                    'Nền tảng học tập trực tuyến',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryBlue,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.login),
                    text: 'Đăng Nhập',
                  ),
                  Tab(
                    icon: Icon(Icons.person_add),
                    text: 'Đăng Ký',
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildSignUpTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'Chào Mừng Trở Lại',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Đăng nhập để tiếp tục học tập',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
          ],
          AppTextField(
            controller: _loginEmailController,
            label: 'Email',
            hint: 'user@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppTheme.spacingM),
          AppTextField(
            controller: _loginPasswordController,
            label: 'Mật khẩu',
            hint: 'Nhập mật khẩu',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureLoginPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureLoginPassword = !_obscureLoginPassword;
                });
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Đăng Nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'Tạo Tài Khoản Mới',
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Đăng ký để bắt đầu học tập',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
          ],
          const Text(
            'Chọn vai trò của bạn',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  role: UserRole.student,
                  icon: Icons.school,
                  label: 'Học sinh',
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildRoleCard(
                  role: UserRole.instructor,
                  icon: Icons.person,
                  label: 'Giảng viên',
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          AppTextField(
            controller: _signUpFullNameController,
            label: 'Họ và Tên',
            hint: 'Ví dụ: Nguyễn Văn A',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppTheme.spacingM),
          AppTextField(
            controller: _signUpEmailController,
            label: 'Email',
            hint: 'user@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppTheme.spacingM),
          AppTextField(
            controller: _signUpPasswordController,
            label: 'Mật khẩu',
            hint: 'Tối thiểu 6 ký tự',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureSignUpPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignUpPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureSignUpPassword = !_obscureSignUpPassword;
                });
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          AppTextField(
            controller: _signUpConfirmPasswordController,
            label: 'Xác nhận mật khẩu',
            hint: 'Nhập lại mật khẩu',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Đăng Ký',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected ? color : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
