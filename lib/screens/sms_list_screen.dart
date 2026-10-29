import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auto_transaction_service.dart';
import '../services/native_listener_bridge.dart';

class SmsListScreen extends StatefulWidget {
  const SmsListScreen({super.key});

  @override
  State<SmsListScreen> createState() => _SmsListScreenState();
}

class _SmsListScreenState extends State<SmsListScreen> {
  List<Map<String, String>> _messages = [];
  bool _isLoading = true;

  final List<Map<String, String>> _sampleBankNotifications = [
    {
      'bank': 'VietinBank iPay',
      'title': 'Tin biến động số dư',
      'body': 'VietinBank:08/10/2026 01:37\nTK:104880072280\nGD:-10,000 VND\nSDC:1,378,944 VND\nND:MoMo CASHIN 0355680504 150574678098 2009',
      'stk': '104880072280',
      'amount': '-10,000 đ',
    },
    {
      'bank': 'MBBank',
      'title': 'Biến động tài khoản MB',
      'body': 'MBBank: TK 0123456789 GD:-50,000VND SD:2,100,000VND luc 12:30. ND: Thanh toan qua QR',
      'stk': '0123456789',
      'amount': '-50,000 đ',
    },
    {
      'bank': 'Vietcombank (VCB)',
      'title': 'VCB Digibank Thông báo',
      'body': 'VCB: SD TK 0071001234567 -20,000 VND luc 15:10. So du 5,200,000 VND. ND: Mua hang Shopee',
      'stk': '0071001234567',
      'amount': '-20,000 đ',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSmsMessages();
  }

  Future<void> _loadSmsMessages() async {
    try {
      List<Map<String, String>> messages = await NativeListenerBridge.getInboxSms();

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncNotificationText(String content) async {
    await AutoTransactionService.instance.processSmsContent(content, force: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã bóc tách số tiền & tự động trừ tiền ví thành công!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Lịch sử Thông báo & SMS', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSub,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Thông báo App Ngân hàng'),
              Tab(text: 'Tin nhắn SMS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Notification Listener History & Auto Sync
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sampleBankNotifications.length,
              itemBuilder: (context, index) {
                final item = _sampleBankNotifications[index];
                final bank = item['bank']!;
                final title = item['title']!;
                final body = item['body']!;
                final stk = item['stk']!;
                final amount = item['amount']!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_active, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                bank,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'STK: $stk',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Thay đổi: $amount', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: () => _syncNotificationText(body),
                            icon: const Icon(Icons.sync, color: Colors.black, size: 16),
                            label: const Text('Đồng bộ trừ tiền', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Tab 2: SMS Inbox
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                ? const Center(
              child: Text('Không tìm thấy tin nhắn nào trong hộp thư!', style: TextStyle(color: AppColors.textSub)),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final body = msg['body'] ?? '';
                final sender = msg['address'] ?? 'Không rõ';

                bool isBankSms = body.toLowerCase().contains('vnd') ||
                    body.toLowerCase().contains('đ') ||
                    body.toLowerCase().contains('tai khoan') ||
                    body.toLowerCase().contains('tk');

                String? extractedStk = isBankSms
                    ? AutoTransactionService.instance.extractAccountNumber(body)
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBankSms ? AppColors.primary : AppColors.border,
                      width: isBankSms ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sender,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          if (isBankSms)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                extractedStk != null ? 'STK: $extractedStk' : 'Biến động số dư',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      ),
                      if (isBankSms) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _syncNotificationText(body),
                            icon: const Icon(Icons.sync, size: 14, color: AppColors.primary),
                            label: const Text('Đồng bộ trừ tiền', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}