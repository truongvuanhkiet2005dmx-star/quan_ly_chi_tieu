import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../database/database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  static const String _backendBaseUrl = AppConstants.backendBaseUrl;

  // F6/F22 Fix: Trả về Future<bool> xác nhận kết quả đồng bộ C# Backend chuẩn xác
  Future<bool> syncTransaction(Map<String, dynamic> tx) async {
    final txId = tx['id'] as int?;
    final eventId = tx['eventId']?.toString().isNotEmpty == true
        ? tx['eventId'].toString()
        : (txId != null ? 'tx_$txId' : 'tx_${DateTime.now().millisecondsSinceEpoch}');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("[SyncService] Chưa đăng nhập Firebase Auth. Bỏ qua gửi API cho $eventId (giữ isSynced = 0).");
        return false;
      }

      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        debugPrint("[SyncService] Không thể lấy Firebase ID Token. Bỏ qua gửi API cho $eventId.");
        return false;
      }

      final String type = (tx['type']?.toString().isNotEmpty == true)
          ? tx['type'].toString()
          : (tx['isExpense'] == 1 ? 'expense' : 'income');

      final String source = tx['walletName']?.toString() ?? 'Ví tài khoản';
      final String bankName = tx['bankName']?.toString() ?? source;
      final String packageName = tx['packageName']?.toString() ?? '';
      final String categoryName = tx['categoryName']?.toString() ?? 'Khác';
      final String note = tx['note']?.toString() ?? '';
      final String occurredAt = tx['date']?.toString().isNotEmpty == true
          ? tx['date'].toString()
          : DateTime.now().toIso8601String();
      final int amount = (tx['amount'] as num?)?.toInt() ?? 0;

      final bodyPayload = {
        'eventId': eventId,
        'amount': amount,
        'type': type,
        'source': source,
        'bankName': bankName,
        'packageName': packageName,
        'occurredAt': occurredAt,
        'categoryName': categoryName,
        'note': note,
      };

      debugPrint("[SyncService] Gửi POST $_backendBaseUrl với eventId: $eventId...");

      final response = await http.post(
        Uri.parse(_backendBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyPayload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("[SyncService] Đồng bộ thành công cho $eventId: ${response.body}");
        if (txId != null) {
          await DatabaseHelper.instance.markTransactionSynced(txId);
        }
        return true;
      } else {
        debugPrint("[SyncService] Lỗi API Status Code: ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("[SyncService] Không thể gửi API đồng bộ (Mất mạng / Lỗi kết nối Backend): $e");
      return false;
    }
  }

  Future<void> syncAllPendingTransactions(int userId) async {
    try {
      final unsynced = await DatabaseHelper.instance.getUnsyncedTransactions(userId);
      if (unsynced.isEmpty) return;

      debugPrint("[SyncService] Phát hiện ${unsynced.length} giao dịch chờ đồng bộ cho userId $userId.");
      for (var tx in unsynced) {
        await syncTransaction(tx);
      }
    } catch (e) {
      debugPrint("[SyncService] Lỗi khi duyệt danh sách đồng bộ chờ: $e");
    }
  }
}