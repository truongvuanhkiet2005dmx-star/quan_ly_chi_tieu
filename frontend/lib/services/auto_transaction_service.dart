import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:firebase_core/firebase_core.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class AutoTransactionService {
  static final AutoTransactionService instance = AutoTransactionService._();
  AutoTransactionService._();

  final Telephony telephony = Telephony.instance;
  final StreamController<bool> onTransactionAdded = StreamController<bool>.broadcast();
  static final Set<String> _processedCache = {};

  void initialize() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
        Permission.phone,
      ].request();

      if (statuses[Permission.sms]!.isGranted) {
        telephony.listenIncomingSms(
          onNewMessage: (SmsMessage message) {
            processSmsContent(message.body ?? '');
          },
          onBackgroundMessage: backgroundMessageHandler,
        );
      }
    } catch (e) {
      debugPrint("Error initializing SMS listener: $e");
    }

    try {
      bool? isGranted = await NotificationsListener.hasPermission;
      if (isGranted != true) {
        debugPrint("Notification Listener Permission not granted. Opening settings...");
        await NotificationsListener.openPermissionSettings();
      }

      await NotificationsListener.initialize(callbackHandle: notificationCallbackHandle);

      NotificationsListener.receivePort?.listen((evt) {
        handleNotificationEvent(evt);
      });
    } catch (e) {
      debugPrint("Error initializing Notification listener: $e");
    }
  }

  void handleNotificationEvent(dynamic evt) {
    String pkg = '';
    String title = '';
    String text = '';
    String message = '';

    if (evt is NotificationEvent) {
      pkg = (evt.packageName ?? '').toLowerCase();
      title = evt.title ?? '';
      text = evt.text ?? '';
      message = evt.message ?? '';
    } else if (evt is Map) {
      pkg = (evt['package_name'] ?? evt['packageName'] ?? '').toString().toLowerCase();
      title = (evt['title'] ?? '').toString();
      text = (evt['text'] ?? '').toString();
      message = (evt['message'] ?? evt['bigText'] ?? evt['text'] ?? '').toString();
    } else if (evt is String) {
      message = evt;
    }

    if (pkg.contains('smart_money') || pkg.contains('example')) {
      return;
    }

    String fullContent = "$title\n$text\n$message".trim();
    if (fullContent.isNotEmpty) {
      processSmsContent(fullContent, packageName: pkg);
    }
  }

  static Future<void> simulateIncomingSms(String messageBody) async {
    await instance.processSmsContent(messageBody, force: true);
  }

  String? extractAccountNumber(String content) {
    final stkRegex = RegExp(
      r'(?:TK|STK|SDTK|Tai\s*khoan|So\s*TK|acc|account)\s*[:=]?\s*([0-9xX*]{4,16})',
      caseSensitive: false,
    );

    final match = stkRegex.firstMatch(content);
    if (match != null) {
      String stk = match.group(1) ?? '';
      if (stk.isNotEmpty) return stk;
    }

    final bankPrefixRegex = RegExp(
      r'(?:VCB|MB|TCB|BIDV|CTG|VPB|ACB|TPB|STB|EIB|Agribank|Momo|ZaloPay|VietinBank)\s+([0-9]{6,16})',
      caseSensitive: false,
    );
    final bankMatch = bankPrefixRegex.firstMatch(content);
    if (bankMatch != null) {
      String stk = bankMatch.group(1) ?? '';
      if (stk.isNotEmpty) return stk;
    }

    return null;
  }

  Map<String, dynamic>? findMatchingWallet(
      List<Map<String, dynamic>> wallets,
      String content,
      String? extractedStk,
      ) {
    if (wallets.isEmpty) return null;

    String lowerContent = content.toLowerCase();

    // 1. Khớp theo STK
    if (extractedStk != null && extractedStk.isNotEmpty) {
      String cleanExtracted = extractedStk.replaceAll(RegExp(r'[^\d]'), '');

      for (var wallet in wallets) {
        String? walletAccNum = wallet['accountNumber']?.toString();
        if (walletAccNum != null && walletAccNum.trim().isNotEmpty) {
          String cleanWalletAcc = walletAccNum.replaceAll(RegExp(r'[^\d]'), '');

          if (cleanWalletAcc.isNotEmpty) {
            if (cleanExtracted == cleanWalletAcc ||
                (cleanExtracted.length >= 4 && cleanWalletAcc.endsWith(cleanExtracted)) ||
                (cleanWalletAcc.length >= 4 && cleanExtracted.endsWith(cleanWalletAcc))) {
              return wallet;
            }
          }
        }
      }
    }

    // 2. Khớp theo từ khóa tên ngân hàng
    final bankKeywords = {
      'vietinbank': ['vietinbank', 'ctg', 'vietin', 'vietin bank', 'ipay'],
      'mbbank': ['mb', 'mbbank', 'mb bank', 'mcbank'],
      'vcb': ['vcb', 'vietcombank'],
      'tcb': ['tcb', 'techcombank'],
      'bidv': ['bidv'],
      'vpb': ['vpb', 'vpbank', 'vp bank'],
      'agribank': ['agribank', 'agri'],
      'acb': ['acb'],
      'tpb': ['tpb', 'tpbank', 'tp bank'],
      'momo': ['momo'],
      'zalopay': ['zalopay', 'zalo'],
    };

    for (var wallet in wallets) {
      String walletNameLower = (wallet['name'] ?? '').toString().toLowerCase();

      for (var entry in bankKeywords.entries) {
        bool smsHasBank = entry.value.any((kw) => lowerContent.contains(kw));
        bool walletHasBank = entry.value.any((kw) => walletNameLower.contains(kw));

        if (smsHasBank && walletHasBank) {
          return wallet;
        }
      }
    }

    // 3. Khớp theo loại ví 'bank'
    for (var wallet in wallets) {
      if (wallet['type'] == 'bank') {
        return wallet;
      }
    }

    // 4. Nếu không có ví riêng, mặc định chọn ví đầu tiên
    return wallets.first;
  }

  Future<void> processSmsContent(String content, {bool force = false, String packageName = ''}) async {
    // 1. Bỏ qua thông báo của chính ứng dụng SmartMoney tạo ra (chống lặp)
    if (!force && (content.contains('SmartMoney') || content.contains('Chi tiêu tự động') || content.contains('Thu nhập tự động'))) {
      return;
    }

    String lowerContent = content.toLowerCase();

    if (!lowerContent.contains('vnd') &&
        !lowerContent.contains('đ') &&
        !lowerContent.contains('d') &&
        !lowerContent.contains('tai khoan') &&
        !lowerContent.contains('tk') &&
        !lowerContent.contains('gd') &&
        !lowerContent.contains('sd') &&
        !lowerContent.contains('chuyen') &&
        !lowerContent.contains('tru') &&
        !lowerContent.contains('cong') &&
        !lowerContent.contains('so du')) {
      return;
    }

    // 2. Chống lặp thông báo trong khoảng thời gian 10 giây (Deduplication Cache)
    String cacheKey = content.trim();
    if (!force && _processedCache.contains(cacheKey)) {
      debugPrint("Bỏ qua thông báo trùng lặp: $cacheKey");
      return;
    }

    if (!force) {
      _processedCache.add(cacheKey);
      Timer(const Duration(seconds: 10), () {
        _processedCache.remove(cacheKey);
      });
    }

    String? extractedStk = extractAccountNumber(content);

    int? parsedAccountBalance;
    final balanceRegex = RegExp(
      r'(?:so\s*du|sd|sdc|sodu)\s*[:=]?\s*(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(?:VND|đ|VNĐ|d)',
      caseSensitive: false,
    );
    final balanceMatch = balanceRegex.firstMatch(content);
    if (balanceMatch != null) {
      String rawBalance = balanceMatch.group(1) ?? '0';
      parsedAccountBalance = int.tryParse(rawBalance.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    }

    final regex = RegExp(r'([+-]?\d{1,3}(?:[.,]\d{3})+|[+-]?\d+)\s*(?:VND|đ|VNĐ|d|k\b)', caseSensitive: false);
    final match = regex.firstMatch(content);

    if (match != null) {
      String rawMatch = match.group(1) ?? '0';
      bool isExpenseFromSign = rawMatch.contains('-');
      String cleaned = rawMatch.replaceAll(RegExp(r'[^\d]'), '');
      int amount = int.tryParse(cleaned) ?? 0;

      if (amount >= 1000) {
        bool isIncome = rawMatch.contains('+') ||
            lowerContent.contains('giao dịch +') ||
            lowerContent.contains('gd: +') ||
            lowerContent.contains('gd:+') ||
            lowerContent.contains('ps:+') ||
            lowerContent.contains('ps: +') ||
            lowerContent.contains('ck:+') ||
            lowerContent.contains('ck: +') ||
            lowerContent.contains('cộng') ||
            lowerContent.contains('cong') ||
            lowerContent.contains('nhận') ||
            lowerContent.contains('nhan');

        bool isExpense = !isIncome && (
            isExpenseFromSign ||
                lowerContent.contains('-') ||
                lowerContent.contains('trừ') ||
                lowerContent.contains('tru') ||
                lowerContent.contains('thanh toan') ||
                lowerContent.contains('chi') ||
                lowerContent.contains('rut tien') ||
                lowerContent.contains('giao dịch -') ||
                lowerContent.contains('gd: -') ||
                lowerContent.contains('gd:-') ||
                lowerContent.contains('ps:-') ||
                lowerContent.contains('ck:-')
        );

        await _saveAutoTransaction(amount, isExpense, content, parsedAccountBalance, extractedStk, packageName: packageName);
      }
    }
  }

  Future<void> _saveAutoTransaction(
      int amount,
      bool isExpense,
      String rawContent,
      int? parsedAccountBalance,
      String? extractedStk, {
        String packageName = '',
      }) async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    final db = await DatabaseHelper.instance.database;

    // 1. Tự động khôi phục userId nếu SharedPreferences trả về null trong Background Isolate
    if (userId == null) {
      final userRows = await db.query('users', orderBy: 'id DESC', limit: 1);
      if (userRows.isNotEmpty) {
        userId = userRows.first['id'] as int?;
      }
      userId ??= 1;
    }

    // 2. Lấy danh sách ví theo userId
    List<Map<String, dynamic>> wallets = await DatabaseHelper.instance.getWallets(userId);

    // Nếu không tìm thấy ví theo userId trong prefs, truy vấn toàn bộ ví trong DB
    if (wallets.isEmpty) {
      wallets = await db.query('wallets', orderBy: 'id ASC');
    }

    // 3. Nếu DB hoàn toàn chưa có ví nào, tự động tạo Ví VietinBank mặc định
    if (wallets.isEmpty) {
      int newWalletId = await db.insert('wallets', {
        'userId': userId,
        'name': 'Ví VietinBank',
        'type': 'bank',
        'balance': parsedAccountBalance ?? 1000000,
        'accountNumber': extractedStk ?? '',
      });
      wallets = [
        {
          'id': newWalletId,
          'userId': userId,
          'name': 'Ví VietinBank',
          'type': 'bank',
          'balance': parsedAccountBalance ?? 1000000,
          'accountNumber': extractedStk ?? '',
        }
      ];
    }

    final matchedWallet = findMatchingWallet(wallets, rawContent, extractedStk) ?? wallets.first;

    final walletId = matchedWallet['id'] as int;
    final walletUserId = matchedWallet['userId'] as int? ?? userId;
    final walletName = matchedWallet['name'] as String;
    final currentBalance = matchedWallet['balance'] as int;

    // Bóc tách dòng ND: (Nội dung giao dịch) ngắn gọn
    String displayNote = rawContent;
    final ndMatch = RegExp(r'ND:\s*(.*)', caseSensitive: false).firstMatch(rawContent);
    if (ndMatch != null) {
      displayNote = ndMatch.group(1)?.trim() ?? rawContent;
    }

    int insertedTxId = 0;
    int newBalance;
    await db.transaction((txn) async {
      if (parsedAccountBalance != null) {
        newBalance = parsedAccountBalance;
      } else {
        newBalance = isExpense ? currentBalance - amount : currentBalance + amount;
      }

      await txn.update(
        'wallets',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [walletId],
      );

      insertedTxId = await txn.insert(
        'transactions',
        {
          'userId': walletUserId,
          'walletId': walletId,
          'toWalletId': null,
          'amount': amount,
          'type': isExpense ? 'expense' : 'income',
          'isExpense': isExpense ? 1 : 0,
          'categoryName': isExpense ? 'Hóa đơn' : 'Tiền lương',
          'date': DateTime.now().toIso8601String(),
          'note': 'Auto: $displayNote',
          'isSynced': 0,
          'eventId': 'tx_0',
        },
      );

      await txn.update(
        'transactions',
        {'eventId': 'tx_$insertedTxId'},
        where: 'id = ?',
        whereArgs: [insertedTxId],
      );
    });

    // Phát tín hiệu sự kiện để UI (HomeTab, WalletsTab, ReportsTab) làm mới màn hình ngay lập tức
    onTransactionAdded.add(true);

    try {
      String typeText = isExpense ? 'Chi tiêu' : 'Thu nhập';
      String formattedAmount = _formatMoney(amount);
      await NotificationService.instance.showNotification(
        'SmartMoney - $typeText tự động',
        '$typeText +$formattedAmount đ tại ví "$walletName".',
      );
    } catch (e) {
      debugPrint("Notification error: $e");
    }

    // Thử đồng bộ sang C# backend ngay sau khi lưu SQLite
    try {
      final txData = {
        'id': insertedTxId,
        'eventId': 'tx_$insertedTxId',
        'amount': amount,
        'type': isExpense ? 'expense' : 'income',
        'walletName': walletName,
        'bankName': walletName,
        'packageName': packageName,
        'categoryName': isExpense ? 'Hóa đơn' : 'Tiền lương',
        'date': DateTime.now().toIso8601String(),
        'note': 'Auto: $displayNote',
      };
      await SyncService.instance.syncTransaction(txData);
    } catch (e) {
      debugPrint("Auto background sync error: $e");
    }
  }

  static String _formatMoney(int amount) {
    final text = amount.toString();
    String result = '';
    for (int i = text.length - 1, count = 1; i >= 0; i--, count++) {
      result = text[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = ',$result';
      }
    }
    return result;
  }
}

@pragma('vm:entry-point')
void notificationCallbackHandle(NotificationEvent evt) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  AutoTransactionService.instance.handleNotificationEvent(evt);
}

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}