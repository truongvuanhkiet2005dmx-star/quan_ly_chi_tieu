import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../core/app_colors.dart';
import 'welcome_setup_screen.dart';
import 'savings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isBiometricEnabled = true;
  bool _isReminderEnabled = true;

  String _username = 'Người dùng';
  String _language = 'Tiếng Việt';
  String _currency = 'VNĐ (₫)';

  final List<String> _customCategories = ['Ăn uống', 'Đi lại', 'Mua sắm', 'Hóa đơn', 'Giải trí', 'Tiền lương', 'Tiền thưởng'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _username = prefs.getString('username') ?? 'Người dùng';
      _language = prefs.getString('language') ?? 'Tiếng Việt';
      _currency = prefs.getString('currency') ?? 'VNĐ (₫)';
      _isBiometricEnabled = prefs.getBool('biometricEnabled') ?? true;
      _isReminderEnabled = prefs.getBool('reminderEnabled') ?? true;
    });
  }

  Future<void> _setBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricEnabled', value);
    setState(() {
      _isBiometricEnabled = value;
    });
  }

  Future<void> _setReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminderEnabled', value);
    setState(() {
      _isReminderEnabled = value;
    });
  }

  Future<void> _openNotificationPermissionSettings() async {
    try {
      bool? isGranted = await NotificationsListener.hasPermission;
      if (isGranted != true) {
        await NotificationsListener.openPermissionSettings();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SmartMoney đã có quyền đọc Thông báo App Ngân hàng!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bật quyền Truy cập Thông báo trong Cài đặt Android.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('username');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeSetupScreen(),
      ),
          (route) => false,
    );
  }

  void _showCategoryManagementSheet() {
    final categoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quản lý Danh mục Thu / Chi', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customCategories.map((cat) {
                      return Chip(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        label: Text(cat, style: const TextStyle(color: AppColors.textDark)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: categoryController,
                          style: const TextStyle(color: AppColors.textDark),
                          decoration: const InputDecoration(
                            hintText: 'Nhập danh mục mới...',
                            hintStyle: TextStyle(color: AppColors.textSub),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () {
                          final text = categoryController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _customCategories.add(text);
                            });
                            setSheetState(() {});
                            categoryController.clear();
                          }
                        },
                        child: const Text('Thêm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFamilyWalletSheet() {
    final emailController = TextEditingController();
    final budgetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quản lý Ví Gia Đình', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Chia sẻ hạn mức thu chi và theo dõi ngân sách cùng thành viên gia đình.', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(
                  labelText: 'Hạn mức ngân sách tháng (VNĐ)',
                  labelStyle: TextStyle(color: AppColors.textSub),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(
                  labelText: 'SĐT hoặc Email người thân cần chia sẻ',
                  labelStyle: TextStyle(color: AppColors.textSub),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thiết lập Ví Gia Đình thành công!'), backgroundColor: Colors.green),
                    );
                  },
                  child: const Text('Lưu thiết lập Ví Gia Đình', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageCurrencyDialog() {
    String tempLanguage = _language;
    String tempCurrency = _currency;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Ngôn ngữ & Tiền tệ', style: TextStyle(color: AppColors.textDark)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tempLanguage,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: const InputDecoration(
                      labelText: 'Ngôn ngữ',
                      labelStyle: TextStyle(color: AppColors.textSub),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tiếng Việt', child: Text('Tiếng Việt')),
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: '日本語', child: Text('日本語')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        tempLanguage = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempCurrency,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: const InputDecoration(
                      labelText: 'Tiền tệ',
                      labelStyle: TextStyle(color: AppColors.textSub),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'VNĐ (₫)', child: Text('VNĐ (₫)')),
                      DropdownMenuItem(value: 'USD (\$)', child: Text('USD (\$)')),
                      DropdownMenuItem(value: 'EUR (€)', child: Text('EUR (€)')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        tempCurrency = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSub)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('language', tempLanguage);
                    await prefs.setString('currency', tempCurrency);

                    if (!mounted) return;

                    setState(() {
                      _language = tempLanguage;
                      _currency = tempCurrency;
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Lưu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Tôi', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, size: 38, color: Colors.black),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_language • $_currency',
                            style: const TextStyle(
                              color: AppColors.textSub,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.savings_outlined,
                  title: 'Sổ tiết kiệm / Hũ mục tiêu',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.family_restroom,
                  title: 'Quản lý Ví gia đình',
                  color: Colors.blueAccent,
                  onTap: _showFamilyWalletSheet,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.category_outlined,
                  title: 'Quản lý danh mục',
                  color: Colors.orangeAccent,
                  onTap: _showCategoryManagementSheet,
                ),
              ]),

              const SizedBox(height: 20),

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Quyền đọc Thông báo App Ngân hàng',
                  color: Colors.amber,
                  onTap: _openNotificationPermissionSettings,
                ),
                _buildDivider(),
                ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.purpleAccent),
                  title: const Text(
                    'Nhắc nhở nhập chi tiêu',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
                  ),
                  trailing: Switch(
                    value: _isReminderEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: _setReminder,
                  ),
                ),
                _buildDivider(),
                ListTile(
                  leading: const Icon(Icons.fingerprint, color: Colors.tealAccent),
                  title: const Text(
                    'Vân tay / FaceID',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
                  ),
                  trailing: Switch(
                    value: _isBiometricEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: _setBiometric,
                  ),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.language,
                  title: 'Ngôn ngữ & Tiền tệ',
                  color: Colors.teal,
                  onTap: _showLanguageCurrencyDialog,
                ),
              ]),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade800),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSub, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 52,
      color: AppColors.border,
    );
  }
}