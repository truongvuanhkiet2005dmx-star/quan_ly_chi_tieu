import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../database/database_helper.dart';
import '../services/auto_transaction_service.dart';

class WalletsTab extends StatefulWidget {
  const WalletsTab({super.key});

  @override
  State<WalletsTab> createState() => _WalletsTabState();
}

class _WalletsTabState extends State<WalletsTab> {
  int? _userId;
  int _totalBalance = 0;
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = true;

  StreamSubscription<bool>? _autoTxSub;

  @override
  void initState() {
    super.initState();
    _loadWallets();

    _autoTxSub = AutoTransactionService.instance.onTransactionAdded.stream.listen((_) {
      if (mounted) {
        _loadWallets();
      }
    });
  }

  @override
  void dispose() {
    _autoTxSub?.cancel();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) return;

    final wallets = await DatabaseHelper.instance.getWallets(userId);

    int total = 0;
    for (final wallet in wallets) {
      total += wallet['balance'] as int;
    }

    if (!mounted) return;

    setState(() {
      _userId = userId;
      _wallets = wallets;
      _totalBalance = total;
      _isLoading = false;
    });
  }

  String _formatMoney(int amount) {
    final text = amount.toString();
    String result = '';
    for (int i = text.length - 1, count = 1; i >= 0; i--, count++) {
      result = text[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = ',$result';
      }
    }
    return '$result đ';
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.account_balance_wallet;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.wallet;
    }
  }

  Future<void> _showAddWalletDialog() async {
    if (_userId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AddWalletDialog(userId: _userId!),
    );

    if (result == true && mounted) {
      _loadWallets();
    }
  }

  Future<void> _showEditWalletDialog(Map<String, dynamic> wallet) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EditWalletDialog(wallet: wallet),
    );

    if (result == true && mounted) {
      _loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Ví & Tài khoản', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWallets,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tài sản ròng',
                        style: TextStyle(color: AppColors.textSub, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatMoney(_totalBalance),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 4, height: 12, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      const Text('Tài sản', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_formatMoney(_totalBalance), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 4, height: 12, color: Colors.orangeAccent),
                                      const SizedBox(width: 6),
                                      const Text('Nợ phải trả', style: TextStyle(color: AppColors.textSub, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('0 đ', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (_wallets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Chưa có ví nào', style: TextStyle(color: AppColors.textSub, fontSize: 16)),
                    ),
                  )
                else
                  ..._wallets.map((wallet) => _buildWalletItem(wallet)),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _showAddWalletDialog,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Thêm tài khoản / ví mới', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletItem(Map<String, dynamic> wallet) {
    final type = wallet['type']?.toString() ?? 'other';
    final icon = _getWalletIcon(type);
    final title = wallet['name']?.toString() ?? '';
    final balance = _formatMoney(wallet['balance'] as int? ?? 0);
    final accountNumber = wallet['accountNumber']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surface,
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
                if (accountNumber != null && accountNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'STK: $accountNumber',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showEditWalletDialog(wallet),
                child: const Text(
                  'Sửa',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddWalletDialog extends StatefulWidget {
  final int userId;

  const _AddWalletDialog({required this.userId});

  @override
  State<_AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<_AddWalletDialog> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _accountNumberController;
  String _type = 'bank';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();
    _accountNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('Thêm tài khoản / ví mới', style: TextStyle(color: AppColors.textDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Tên ví (VD: VietinBank, MB Bank, Tiền mặt)',
                labelStyle: TextStyle(color: AppColors.textSub),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Số tài khoản (Để ghép nối SMS)',
                labelStyle: TextStyle(color: AppColors.textSub),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Số dư ban đầu',
                labelStyle: TextStyle(color: AppColors.textSub),
                suffixText: 'VNĐ',
                suffixStyle: TextStyle(color: AppColors.textSub),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy', style: TextStyle(color: AppColors.textSub)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () async {
            final name = _nameController.text.trim();
            final accNum = _accountNumberController.text.trim();
            final balance = int.tryParse(_balanceController.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;

            if (name.isEmpty) return;

            await DatabaseHelper.instance.insertWallet({
              'userId': widget.userId,
              'name': name,
              'balance': balance,
              'type': _type,
              'accountNumber': accNum.isEmpty ? null : accNum,
            });

            if (!mounted) return;
            Navigator.pop(context, true);
          },
          child: const Text('Thêm ví', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _EditWalletDialog extends StatefulWidget {
  final Map<String, dynamic> wallet;

  const _EditWalletDialog({required this.wallet});

  @override
  State<_EditWalletDialog> createState() => _EditWalletDialogState();
}

class _EditWalletDialogState extends State<_EditWalletDialog> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _accountNumberController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet['name']?.toString() ?? '');
    _balanceController = TextEditingController(text: widget.wallet['balance']?.toString() ?? '0');
    _accountNumberController = TextEditingController(text: widget.wallet['accountNumber']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletId = widget.wallet['id'] as int;

    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('Chỉnh sửa ví / STK', style: TextStyle(color: AppColors.textDark)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(labelText: 'Tên ví', labelStyle: TextStyle(color: AppColors.textSub)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(labelText: 'Số tài khoản / STK', labelStyle: TextStyle(color: AppColors.textSub)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(labelText: 'Số dư hiện tại', labelStyle: TextStyle(color: AppColors.textSub), suffixText: 'VNĐ'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('Xác nhận xóa ví', style: TextStyle(color: AppColors.textDark)),
                content: Text(
                  'Bạn có chắc chắn muốn xóa ví "${widget.wallet['name']}" không? Mọi lịch sử giao dịch thuộc ví này sẽ bị xóa khỏi cơ sở dữ liệu SQLite.',
                  style: const TextStyle(color: AppColors.textSub),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy', style: TextStyle(color: AppColors.textSub)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await DatabaseHelper.instance.deleteWallet(walletId);
              if (!mounted) return;
              Navigator.pop(context, true);
            }
          },
          child: const Text('Xóa ví', style: TextStyle(color: Colors.redAccent)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () async {
            final name = _nameController.text.trim();
            final accNum = _accountNumberController.text.trim();
            final balance = int.tryParse(_balanceController.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;

            if (name.isEmpty) return;

            await DatabaseHelper.instance.updateWallet(walletId, {
              'name': name,
              'balance': balance,
              'accountNumber': accNum.isEmpty ? null : accNum,
            });

            if (!mounted) return;
            Navigator.pop(context, true);
          },
          child: const Text('Lưu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}