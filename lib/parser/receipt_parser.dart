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
// Tin nhắn ngân hàng: số tiền có dấu đứng trước, ví dụ "-200,000 VND"
final _signed = RegExp(r'[+\-−]\s*' + _num + r'\s*(?:đ|vnđ|vnd)', caseSensitive: false);
// Số dư tài khoản: không phải số tiền giao dịch nên phải loại ra
final _balance = RegExp(r'\b(?:số\s*dư|so\s*du|sd)\D{0,8}' + _num, caseSensitive: false);
// Nội dung chuyển khoản. \b để không khớp nhầm chữ "ND" nằm trong "VND"
final _note = RegExp(r'\b(?:nd|nội\s*dung|noi\s*dung)\s*[:.]\s*(.+)', caseSensitive: false);
final _date = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})');
final _letters = RegExp(r'\p{L}{3,}', unicode: true);

int _toInt(String s) => int.parse(s.replaceAll(RegExp(r'[.,]'), ''));

class ReceiptParser {
  static ParsedReceipt parse(String text) {
    int? amount;
    final total = _total.firstMatch(text);
    final signed = _signed.firstMatch(text);
    if (total != null) {
      amount = _toInt(total.group(1)!);          // hóa đơn có dòng Tổng cộng
    } else if (signed != null) {
      amount = _toInt(signed.group(1)!);         // tin nhắn ngân hàng có dấu +/-
    } else {
      // Còn lại: lấy số lớn nhất có đơn vị tiền, nhưng bỏ các số là số dư
      final balances = _balance.allMatches(text).map((m) => _toInt(m.group(1)!)).toSet();
      final all = _money.allMatches(text).map((m) => _toInt(m.group(1)!)).where((v) => !balances.contains(v)).toList();
      if (all.isNotEmpty) amount = all.reduce((a, b) => a > b ? a : b);
    }

    DateTime? date;
    final d = _date.firstMatch(text);
    if (d != null) {
      final day = int.parse(d.group(1)!), month = int.parse(d.group(2)!), year = int.parse(d.group(3)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) date = DateTime(year, month, day);
    }

    // Tên: ưu tiên nội dung chuyển khoản, không có thì lấy dòng đầu tiên có chữ
    final note = _note.firstMatch(text)?.group(1)?.trim();
    final firstLine = text.split('\n').map((l) => l.trim()).firstWhere(_letters.hasMatch, orElse: () => '');
    final merchant = (note != null && note.isNotEmpty) ? note : firstLine;
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
