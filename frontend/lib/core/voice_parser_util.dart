class VoiceParserUtil {
  static Map<String, dynamic> parseVoiceInput(String text) {
    if (text.trim().isEmpty) {
      return {'amount': 0, 'category': 'Khác', 'note': text};
    }

    String lower = text.toLowerCase();
    int amount = 0;

    // 1. Shorthand "50k", "100k", "20k"
    final kRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(k|nghìn|ngàn)\b', caseSensitive: false);
    final kMatch = kRegex.firstMatch(lower);
    if (kMatch != null) {
      double numVal = double.tryParse(kMatch.group(1)!.replaceAll(',', '.')) ?? 0;
      amount = (numVal * 1000).round();
    }

    // 2. Shorthand "1.5 triệu", "2 tr"
    if (amount == 0) {
      final trieuRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(triệu|tr\b)', caseSensitive: false);
      final trieuMatch = trieuRegex.firstMatch(lower);
      if (trieuMatch != null) {
        double numVal = double.tryParse(trieuMatch.group(1)!.replaceAll(',', '.')) ?? 0;
        amount = (numVal * 1000000).round();
      }
    }

    // 3. Shorthand "200 trăm nghìn"
    if (amount == 0) {
      final tramNghinRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(trăm nghìn|trăm ngàn)', caseSensitive: false);
      final tramNghinMatch = tramNghinRegex.firstMatch(lower);
      if (tramNghinMatch != null) {
        double numVal = double.tryParse(tramNghinMatch.group(1)!.replaceAll(',', '.')) ?? 0;
        amount = (numVal * 100000).round();
      }
    }

    // 4. Raw digits e.g. "50000"
    if (amount == 0) {
      final digitRegex = RegExp(r'(\d{4,12})');
      final digitMatch = digitRegex.firstMatch(lower);
      if (digitMatch != null) {
        amount = int.tryParse(digitMatch.group(1)!) ?? 0;
      }
    }

    // 5. Vietnamese word numbers e.g. "một trăm hai mươi nghìn"
    if (amount == 0 && (lower.contains('ngàn') || lower.contains('nghìn') || lower.contains('trăm') || lower.contains('triệu'))) {
      if (lower.contains('chín trăm')) {
        amount += 900000;
      } else if (lower.contains('tám trăm')) {
        amount += 800000;
      } else if (lower.contains('bảy trăm')) {
        amount += 700000;
      } else if (lower.contains('sáu trăm')) {
        amount += 600000;
      } else if (lower.contains('năm trăm')) {
        amount += 500000;
      } else if (lower.contains('bốn trăm')) {
        amount += 400000;
      } else if (lower.contains('ba trăm')) {
        amount += 300000;
      } else if (lower.contains('hai trăm')) {
        amount += 200000;
      } else if (lower.contains('một trăm') || lower.contains('trăm')) {
        amount += 100000;
      }

      if (lower.contains('chín mươi')) {
        amount += 90000;
      } else if (lower.contains('tám mươi')) {
        amount += 80000;
      } else if (lower.contains('bảy mươi')) {
        amount += 70000;
      } else if (lower.contains('sáu mươi')) {
        amount += 60000;
      } else if (lower.contains('năm mươi')) {
        amount += 50000;
      } else if (lower.contains('bốn mươi')) {
        amount += 40000;
      } else if (lower.contains('ba mươi')) {
        amount += 30000;
      } else if (lower.contains('hai mươi')) {
        amount += 20000;
      } else if (lower.contains('mười')) {
        amount += 10000;
      }

      if (lower.contains('năm ngàn') || lower.contains('năm nghìn')) {
        amount += 5000;
      } else if (lower.contains('mười nghìn') || lower.contains('mười ngàn')) {
        amount += 10000;
      }
    }

    String category = 'Khác';
    if (lower.contains('ăn') || lower.contains('cà phê') || lower.contains('phở') || lower.contains('cơm') || lower.contains('uống') || lower.contains('trà')) {
      category = 'Đồ ăn';
    } else if (lower.contains('xe') || lower.contains('xăng') || lower.contains('grab') || lower.contains('đi lại') || lower.contains('bus')) {
      category = 'Đi lại';
    } else if (lower.contains('mua') || lower.contains('shopee') || lower.contains('sắm') || lower.contains('quần áo')) {
      category = 'Mua sắm';
    } else if (lower.contains('điện thoại') || lower.contains('nạp thẻ') || lower.contains('4g')) {
      category = 'Điện thoại';
    } else if (lower.contains('phim') || lower.contains('xem') || lower.contains('chơi') || lower.contains('game')) {
      category = 'Giải trí';
    } else if (lower.contains('lương') || lower.contains('thưởng')) {
      category = 'Lương';
    }

    return {
      'amount': amount,
      'category': category,
      'note': text,
    };
  }
}