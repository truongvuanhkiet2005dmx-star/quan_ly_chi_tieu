import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../database/database_helper.dart';
import 'register_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  final String language;
  final String currency;

  const LoginScreen({
    super.key,
    required this.language,
    required this.currency,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(
        'Vui lòng nhập đầy đủ thông tin!',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await DatabaseHelper.instance.loginUser(
        username,
        password,
      );

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _isLoading = false;
        });

        _showSnackBar(
          'Tên đăng nhập hoặc mật khẩu không đúng!',
          Colors.red,
        );
        return;
      }

      // Đăng nhập Firebase Auth ngầm (nếu có mạng & đã cấu hình Firebase)
      try {
        final email = username.contains('@') ? username : '$username@smartmoney.com';
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (fe) {
        debugPrint("[LoginScreen] Đăng nhập Firebase Auth chưa thành công (Chế độ Offline): $fe");
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('userId', user['id'] as int);
      await prefs.setString(
        'username',
        user['username'] as String,
      );
      await prefs.setString(
        'language',
        widget.language,
      );
      await prefs.setString(
        'currency',
        widget.currency,
      );

      setState(() {
        _isLoading = false;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Có lỗi xảy ra khi đăng nhập!',
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
              const SizedBox(height: 10),

              const Text(
                'Đăng Nhập',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Đơn vị: ${widget.currency} • Ngôn ngữ: ${widget.language}',
                style: const TextStyle(
                  fontSize: 13,
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
                decoration: InputDecoration(
                  hintText: 'Nhập tên hoặc email...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
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
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
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
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
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
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(
                      color: AppColors.textSub,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}