import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_colors.dart';
import 'screens/welcome_setup_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';
import 'services/auto_transaction_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (e) {
    print("Error initializing date formatting: $e");
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    print("Error initializing NotificationService: $e");
  }

  try {
    AutoTransactionService.instance.initialize();
  } catch (e) {
    print("Error initializing AutoTransactionService: $e");
  }

  runApp(const SmartMoneyApp());
}

class SmartMoneyApp extends StatelessWidget {
  const SmartMoneyApp({super.key});

  Future<Widget> _getStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      return const MainNavigationScreen();
    }

    return const WelcomeSetupScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartMoney',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'sans-serif',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return const WelcomeSetupScreen();
          }

          return snapshot.data ?? const WelcomeSetupScreen();
        },
      ),
    );
  }
}