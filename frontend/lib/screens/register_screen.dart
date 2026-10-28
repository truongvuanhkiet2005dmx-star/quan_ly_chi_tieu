import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../database/database_helper.dart';
import 'initial_wallet_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin!', Colors.orange);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp!', Colors.red);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Mật khẩu phải có ít nhất 6 ký tự!', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await DatabaseHelper.instance.registerUser(
        username,
        password,
      );

      // Đăng ký Firebase Auth ngầm (nếu có mạng & đã cấu hình Firebase)
      try {
        final email = username.contains('@') ? username : '$username@smartmoney.com';
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (fe) {
        debugPrint("[RegisterScreen] Đăng ký Firebase Auth chưa thành công (Chế độ Offline): $fe");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);
      await prefs.setString('username', username);
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InitialWalletSetupScreen(
            userId: userId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Tên đăng nhập này đã được sử dụng!',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tạo Tài Khoản',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bắt đầu hành trình quản lý tài chính của bạn',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Tên đăng nhập / Email',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _usernameController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: _inputDecoration(
                  'Nhập tên hoặc email...',
                  Icons.person_outline,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Mật khẩu',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textDark),
                decoration: _passwordDecoration(
                  'Nhập mật khẩu...',
                  _obscurePassword,
                      () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Xác nhận mật khẩu',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: AppColors.textDark),
                decoration: _passwordDecoration(
                  'Nhập lại mật khẩu...',
                  _obscureConfirm,
                      () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Đăng ký',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint,
      IconData icon,
      ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textSub,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: AppColors.card,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration(
      String hint,
      bool isObscure,
      VoidCallback onToggle,
      ) {
    return _inputDecoration(
      hint,
      Icons.lock_outline,
    ).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          isObscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.primary,
        ),
        onPressed: onToggle,
      ),
    );
  }
}