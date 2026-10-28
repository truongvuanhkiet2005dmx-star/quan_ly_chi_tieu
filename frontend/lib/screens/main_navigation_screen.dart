import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../core/app_colors.dart';
import 'home_tab.dart';
import 'reports_tab.dart';
import 'wallets_tab.dart';
import 'profile_tab.dart';
import 'add_transaction_screen.dart';
import 'bill_scanner_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _refreshKey = 0;

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';

  List<Widget> get _screens => [
    HomeTab(
      key: ValueKey('home_$_refreshKey'),
    ),
    ReportsTab(
      key: ValueKey('reports_$_refreshKey'),
    ),
    WalletsTab(
      key: ValueKey('wallets_$_refreshKey'),
    ),
    ProfileTab(
      key: ValueKey('profile_$_refreshKey'),
    ),
  ];

  Future<void> _openAddTransaction({String? amount, String? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          initialAmount: amount,
          initialNote: note,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  Future<void> _openBillScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BillScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      final amount = result.toString();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTransactionScreen(
            initialAmount: amount,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    }
  }

  Map<String, String> _parseVoiceText(String text) {
    if (text.isEmpty) return {'amount': '0', 'note': ''};

    String lower = text.toLowerCase();
    int amount = 0;

    // 1. Check shorthand numbers e.g. 50k, 100k, 20k
    final kRegex = RegExp(r'(\d+)\s*k\b', caseSensitive: false);
    final kMatch = kRegex.firstMatch(lower);
    if (kMatch != null) {
      int base = int.tryParse(kMatch.group(1) ?? '0') ?? 0;
      amount = base * 1000;
    }

    // 2. Check million shorthand e.g. 1.5 triệu, 2 triệu
    if (amount == 0) {
      final trieuRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*triệu', caseSensitive: false);
      final trieuMatch = trieuRegex.firstMatch(lower);
      if (trieuMatch != null) {
        double base = double.tryParse(trieuMatch.group(1)?.replaceAll(',', '.') ?? '0') ?? 0;
        amount = (base * 1000000).round();
      }
    }

    // 3. Check raw digits e.g. 50000, 100000
    if (amount == 0) {
      final digitRegex = RegExp(r'(\d{4,10})');
      final digitMatch = digitRegex.firstMatch(lower);
      if (digitMatch != null) {
        amount = int.tryParse(digitMatch.group(1) ?? '0') ?? 0;
      }
    }

    // 4. Check Vietnamese word numbers
    if (amount == 0) {
      if (lower.contains('ngàn') || lower.contains('nghìn')) {
        int baseMultiplier = 1000;
        if (lower.contains('một trăm') || lower.contains('trăm')) baseMultiplier = 100000;
        else if (lower.contains('hai trăm')) baseMultiplier = 200000;
        else if (lower.contains('ba trăm')) baseMultiplier = 300000;
        else if (lower.contains('bốn trăm')) baseMultiplier = 400000;
        else if (lower.contains('năm trăm')) baseMultiplier = 500000;
        else if (lower.contains('sáu trăm')) baseMultiplier = 600000;
        else if (lower.contains('bảy trăm')) baseMultiplier = 700000;
        else if (lower.contains('tám trăm')) baseMultiplier = 800000;
        else if (lower.contains('chín trăm')) baseMultiplier = 900000;
        else if (lower.contains('chín mươi')) baseMultiplier = 90000;
        else if (lower.contains('tám mươi')) baseMultiplier = 80000;
        else if (lower.contains('bảy mươi')) baseMultiplier = 70000;
        else if (lower.contains('sáu mươi')) baseMultiplier = 60000;
        else if (lower.contains('năm mươi')) baseMultiplier = 50000;
        else if (lower.contains('bốn mươi')) baseMultiplier = 40000;
        else if (lower.contains('ba mươi')) baseMultiplier = 30000;
        else if (lower.contains('hai mươi')) baseMultiplier = 20000;
        else if (lower.contains('mười')) baseMultiplier = 10000;
        else if (lower.contains('năm')) baseMultiplier = 5000;

        amount = baseMultiplier;
      }
    }

    // Clean note text by stripping out number words
    String note = text
        .replaceAll(RegExp(r'\b\d+\s*k\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d+(?:[.,]\d+)?\s*triệu\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{4,10}\b'), '')
        .replaceAll(RegExp(r'\b(ba|năm|hai|bốn|sáu|bảy|tám|chín)?\s*(mươi|trăm)?\s*(ngàn|nghìn|đồng|vnd|vnđ)\b', caseSensitive: false), '')
        .trim();

    return {
      'amount': amount > 0 ? amount.toString() : '0',
      'note': note.isNotEmpty ? note : text,
    };
  }

  Future<void> _startVoiceInput() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cấp quyền Micro trong Cài đặt điện thoại!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _speechAvailable = await _speech.initialize();

    if (!_speechAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể khởi động nhận diện giọng nói. Hãy kiểm tra Micro!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'Tiếng Việt';
    String localeId = 'vi_VN';
    if (lang == 'English') {
      localeId = 'en_US';
    } else if (lang == '日本語') {
      localeId = 'ja_JP';
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  Future<void> _cancelVoiceInput() async {
    await _speech.cancel();

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _recognizedText = '';
    });
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionButton(
                    icon: Icons.remove_circle,
                    color: Colors.redAccent,
                    label: 'Chi/Thu',
                    onTap: () {
                      Navigator.pop(context);
                      _openAddTransaction();
                    },
                  ),

                  _actionButton(
                    icon: Icons.camera_alt,
                    color: Colors.blueAccent,
                    label: 'Quét Bill',
                    onTap: () {
                      Navigator.pop(context);
                      _openBillScanner();
                    },
                  ),

                  _actionButton(
                    icon: Icons.mic,
                    color: AppColors.primary,
                    label: 'Giọng nói',
                    onTap: () {
                      Navigator.pop(context);
                      _showVoiceInputDialog();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showVoiceInputDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: const EdgeInsets.only(
                top: 32,
                bottom: 40,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isListening
                        ? 'Đang nghe...'
                        : 'Nhập bằng giọng nói',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Text(
                      _recognizedText.isEmpty
                          ? 'Ví dụ: "Ăn sáng ba mươi ngàn" hoặc "Cà phê 50k"'
                          : _recognizedText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontStyle: _recognizedText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  GestureDetector(
                    onTap: () async {
                      if (_isListening) {
                        await _stopVoiceInput();
                      } else {
                        await _startVoiceInput();
                      }

                      setDialogState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.red.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? Colors.red.withOpacity(0.3)
                                : AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? Colors.red
                                : AppColors.primary,
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.black,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_recognizedText.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        final parsed = _parseVoiceText(_recognizedText);
                        Navigator.pop(context);
                        _openAddTransaction(
                          amount: parsed['amount'],
                          note: parsed['note'],
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Tiếp tục nhập giao dịch',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () async {
                      await _cancelVoiceInput();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],

      floatingActionButton: SizedBox(
        width: 54,
        height: 54,
        child: FloatingActionButton(
          onPressed: () {
            _showActionMenu(context);
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            size: 28,
          ),
        ),
      ),

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.ballot_outlined,
                label: 'Trang chủ',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.pie_chart_outline_rounded,
                label: 'Biểu đồ',
                index: 1,
              ),

              const SizedBox(width: 54),

              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Ví',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Tôi',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}