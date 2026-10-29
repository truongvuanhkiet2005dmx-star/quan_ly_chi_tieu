class VoiceParserUtil {
  static Map<String, dynamic> parseVoiceInput(String text) {
    if (text.trim().isEmpty) {
      return {'amount': 0, 'category': 'Khác', 'note': text};
    }

    String lower = text.toLowerCase();
    int amount = 0;

    // F1 Fix: Dùng (?!\p{L}) thay vì \b để regex hoạt động đúng với Tiếng Việt có dấu
    // 1. Shorthand "50k", "100k", "20k"
    final kRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(k|nghìn|ngàn)(?!\p{L})', caseSensitive: false, unicode: true);
    final kMatch = kRegex.firstMatch(lower);
    if (kMatch != null) {
      double numVal = double.tryParse(kMatch.group(1)!.replaceAll(',', '.')) ?? 0;
      amount = (numVal * 1000).round();
    }

    // 2. Shorthand "1.5 triệu", "2 tr", "1 triệu"
    if (amount == 0) {
      // F3 Fix: Parse số Ả Rập phía trước chữ triệu (Shorthand đã handle tốt)
      final trieuRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(triệu|tr(?!\p{L}))', caseSensitive: false, unicode: true);
      final trieuMatch = trieuRegex.firstMatch(lower);
      if (trieuMatch != null) {
        double numVal = double.tryParse(trieuMatch.group(1)!.replaceAll(',', '.')) ?? 0;
        amount = (numVal * 1000000).round();
      }
    }

    // 3. Shorthand "200 trăm nghìn"
    if (amount == 0) {
      final tramNghinRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(trăm nghìn|trăm ngàn)', caseSensitive: false, unicode: true);
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

    // 5. Full Vietnamese word-number parser (Fix #1 & #28)
    if (amount == 0 && (lower.contains('ngàn') || lower.contains('nghìn') || lower.contains('trăm') || lower.contains('triệu') || lower.contains('mươi') || lower.contains('mười'))) {
      amount = _parseVietnameseWordsToNumber(lower);
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

  static int _parseVietnameseWordsToNumber(String text) {
    int total = 0;

    // Phân tách nhánh hàng Triệu
    if (text.contains('triệu') || text.contains(' tr ')) {
      final parts = text.split(RegExp(r'triệu|tr(?!\p{L})', unicode: true));
      int millions = _parseSubThousand(parts[0]);
      if (millions == 0) millions = 1; // e.g. "một triệu"
      total += millions * 1000000;

      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        total += _parseSubMillions(parts[1]);
      }
      return total;
    }

    return _parseSubMillions(text);
  }

  static int _parseSubMillions(String text) {
    int total = 0;
    if (text.contains('nghìn') || text.contains('ngàn')) {
      final parts = text.split(RegExp(r'nghìn|ngàn'));
      int thousands = _parseSubThousand(parts[0]);
      if (thousands == 0) thousands = 1;
      total += thousands * 1000;

      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        total += _parseSubThousand(parts[1]);
      }
      return total;
    }

    return _parseSubThousand(text);
  }

  // F2 Fix: Tách token từ từ trái sang phải, không dùng contains gây cộng dồn 
  static int _parseSubThousand(String text) {
    int sum = 0;
    String t = text;

    // Ưu tiên check số Ả rập phía trước (Fix #3 cho chuỗi mix "2 triệu")
    final numMatch = RegExp(r'(\d+)').firstMatch(t);
    if (numMatch != null) {
      return int.tryParse(numMatch.group(1)!) ?? 0;
    }

    // Hàng trăm
    if (t.contains('chín trăm')) { sum += 900; t = t.replaceFirst('chín trăm', ''); }
    else if (t.contains('tám trăm')) { sum += 800; t = t.replaceFirst('tám trăm', ''); }
    else if (t.contains('bảy trăm')) { sum += 700; t = t.replaceFirst('bảy trăm', ''); }
    else if (t.contains('sáu trăm')) { sum += 600; t = t.replaceFirst('sáu trăm', ''); }
    else if (t.contains('năm trăm')) { sum += 500; t = t.replaceFirst('năm trăm', ''); }
    else if (t.contains('bốn trăm')) { sum += 400; t = t.replaceFirst('bốn trăm', ''); }
    else if (t.contains('ba trăm')) { sum += 300; t = t.replaceFirst('ba trăm', ''); }
    else if (t.contains('hai trăm')) { sum += 200; t = t.replaceFirst('hai trăm', ''); }
    else if (t.contains('một trăm')) { sum += 100; t = t.replaceFirst('một trăm', ''); }
    else if (t.contains('trăm')) { sum += 100; t = t.replaceFirst('trăm', ''); }

    // Hàng mươi/mười
    int tens = 0;
    if (t.contains('chín mươi')) { tens = 90; t = t.replaceFirst('chín mươi', ''); }
    else if (t.contains('tám mươi')) { tens = 80; t = t.replaceFirst('tám mươi', ''); }
    else if (t.contains('bảy mươi')) { tens = 70; t = t.replaceFirst('bảy mươi', ''); }
    else if (t.contains('sáu mươi')) { tens = 60; t = t.replaceFirst('sáu mươi', ''); }
    else if (t.contains('năm mươi')) { tens = 50; t = t.replaceFirst('năm mươi', ''); }
    else if (t.contains('bốn mươi')) { tens = 40; t = t.replaceFirst('bốn mươi', ''); }
    else if (t.contains('ba mươi')) { tens = 30; t = t.replaceFirst('ba mươi', ''); }
    else if (t.contains('hai mươi')) { tens = 20; t = t.replaceFirst('hai mươi', ''); }
    else if (t.contains('mười')) { tens = 10; t = t.replaceFirst('mười', ''); }

    sum += tens;

    // Hàng đơn vị (Fix #28 hỗ trợ "lăm")
    if (t.contains('lăm') || (tens > 0 && t.contains('năm'))) {
      sum += 5;
    } else if (tens == 0 && t.contains('năm')) {
      sum += 5;
    } else if (t.contains('chín')) {
      sum += 9;
    } else if (t.contains('tám')) {
      sum += 8;
    } else if (t.contains('bảy')) {
      sum += 7;
    } else if (t.contains('sáu')) {
      sum += 6;
    } else if (t.contains('bốn') || t.contains('tư')) {
      sum += 4;
    } else if (t.contains('ba')) {
      sum += 3;
    } else if (t.contains('hai')) {
      sum += 2;
    } else if (t.contains('mốt') || (tens == 0 && (t.contains('một')))) {
      sum += 1;
    }

    return sum;
  }
}