import '../models/expense.dart';

class ParsedReceipt {
  final int? amount;
  final DateTime? date;
  final String? merchant;
  const ParsedReceipt({this.amount, this.date, this.merchant});
}

// Số tiền kiểu VN: 150.000 hoặc 150,000 hoặc 150000
const _num = r'(\d{1,3}(?:[.,]\d{3})+|\d+)';
final _total = RegExp(r'(?:tổng\s*cộng|thành\s*tiền|tổng\s*tiền|total)\D{0,12}' + _num, caseSensitive: false);
final _money = RegExp(_num + r'\s*(?:đ|vnđ|vnd|₫)', caseSensitive: false);
final _date = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})');
final _letters = RegExp(r'\p{L}{3,}', unicode: true);

int _toInt(String s) => int.parse(s.replaceAll(RegExp(r'[.,]'), ''));

class ReceiptParser {
  static ParsedReceipt parse(String text) {
    int? amount;
    final t = _total.firstMatch(text);
    if (t != null) {
      amount = _toInt(t.group(1)!);
    } else {
      // Không có dòng "Tổng cộng": lấy số lớn nhất đi kèm đơn vị tiền
      final all = _money.allMatches(text).map((m) => _toInt(m.group(1)!)).toList();
      if (all.isNotEmpty) amount = all.reduce((a, b) => a > b ? a : b);
    }
    DateTime? date;
    final d = _date.firstMatch(text);
    if (d != null) {
      final day = int.parse(d.group(1)!), month = int.parse(d.group(2)!), year = int.parse(d.group(3)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) date = DateTime(year, month, day);
    }
    // Tên cửa hàng: dòng đầu tiên có chữ (heuristic đơn giản)
    final merchant = text.split('\n').map((l) => l.trim()).firstWhere(_letters.hasMatch, orElse: () => '');
    return ParsedReceipt(amount: amount, date: date, merchant: merchant.isEmpty ? null : merchant);
  }

  static const _rules = <String, String>{
    r'coffee|cafe|cà phê|trà sữa|căn tin|nhà hàng|quán|phở|cơm|highlands': 'Ăn uống (F&B)',
    r'sách|fahasa|văn phòng phẩm|photo|in ấn': 'Học tập & Giáo trình',
    r'xăng|petrolimex|grab|taxi|gửi xe': 'Di chuyển & Xăng xe',
    r'circle k|winmart|coopmart|bách hóa|siêu thị|lotte|gs25': 'Mua sắm & Siêu thị',
    r'cgv|lotte cinema|rạp|game|karaoke': 'Giải trí & Hoạt động',
  };
  static String guessCategory(String text) {
    for (final e in _rules.entries) {
      if (RegExp(e.key, caseSensitive: false).hasMatch(text)) return e.value;
    }
    return categories.first.name;
  }
}
