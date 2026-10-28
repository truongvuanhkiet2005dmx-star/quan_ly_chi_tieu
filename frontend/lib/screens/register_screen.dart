import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/app_colors.dart';
import '../database/database_helper.dart';
import 'initial_wallet_setup_screen.dart';
import 'main_navigation_screen.dart';

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
      User? fbUser;

      // 1. Thử đăng ký Firebase Auth nếu là email hợp lệ
      if (username.contains('@')) {
        try {
          final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: username,
            password: password,
          );
          fbUser = cred.user;
        } on FirebaseAuthException catch (fe) {
          if (fe.code == 'email-already-in-use') {
            if (!mounted) return;
            setState(() { _isLoading = false; });
            _showSnackBar('Email này đã được đăng ký trên Firebase!', Colors.red);
            return;
          } else if (fe.code == 'weak-password') {
            if (!mounted) return;
            setState(() { _isLoading = false; });
            _showSnackBar('Mật khẩu quá yếu!', Colors.red);
            return;
          } else if (fe.code == 'network-request-failed') {
            debugPrint("[RegisterScreen] Mất mạng. Tiếp tục đăng ký SQLite Cục bộ...");
          }
        } catch (fe) {
          debugPrint("[RegisterScreen] Lỗi kết nối Firebase Auth (Chế độ Offline): $fe");
        }
      }

      // 2. Đăng ký CSDL SQLite cục bộ (mã hóa PBKDF2-HMAC-SHA256)
      final userId = await DatabaseHelper.instance.registerUser(
        username,
        password,
      );

      if (fbUser != null && fbUser.email != null) {
        await DatabaseHelper.instance.findOrCreateUserByFirebaseUid(
          firebaseUid: fbUser.uid,
          email: fbUser.email!,
          displayName: fbUser.displayName,
        );
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null || user.email == null || user.email!.isEmpty) {
        throw Exception("Không thể lấy thông tin Email từ Google.");
      }

      // Tìm hoặc tạo tài khoản SQLite tương ứng với Firebase UID chuẩn xác
      final sqliteUser = await DatabaseHelper.instance.findOrCreateUserByFirebaseUid(
        firebaseUid: user.uid,
        email: user.email!,
        displayName: user.displayName ?? user.email!,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('userId', sqliteUser['id'] as int);
      await prefs.setString('username', sqliteUser['username'] as String);

      if (!mounted) return;

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
        'Đăng nhập Google chưa thành công. Hãy thử lại!',
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
              const SizedBox(height: 28),

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

              const SizedBox(height: 28),

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

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.g_mobiledata, color: Colors.redAccent, size: 28),
                label: const Text(
                  'Đăng ký bằng Google',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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