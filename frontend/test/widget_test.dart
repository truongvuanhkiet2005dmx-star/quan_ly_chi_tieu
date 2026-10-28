import 'package:flutter_test/flutter_test.dart';
import 'package:smart_money_v2/main.dart'; // Đổi tên package ở đây

void main() {
  testWidgets('Kiểm tra khởi chạy ứng dụng', (WidgetTester tester) async {
    // Đã thay MyApp() thành SmartMoneyApp()
    await tester.pumpWidget(const SmartMoneyApp());
  });
}