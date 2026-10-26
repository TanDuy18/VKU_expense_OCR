import 'dart:math' as math;
import '../models/expense.dart';

class ParsedReceipt {
  final int? amount;
  final DateTime? date;
  final String? merchant;
  final bool isIncome; // tin nhắn "tiền vào": app chỉ theo dõi chi tiêu nên UI sẽ cảnh báo
  const ParsedReceipt({this.amount, this.date, this.merchant, this.isIncome = false});
}

// ---------- Bỏ dấu tiếng Việt ----------
// ML Kit (bản Latin) hay rớt/sai dấu: "Tổng" -> "Tong"/"Tông". Nên mọi so khớp chạy trên văn bản KHÔNG DẤU.
// Dart không có normalize() nên dùng bảng thay chữ: 17 a, 11 e, 5 i, 17 o, 11 u, 5 y, rồi đ và vài chữ Latin lạ OCR hay sinh ra.
const _from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđäëïöüñç';
final _to = '${'a' * 17}${'e' * 11}${'i' * 5}${'o' * 17}${'u' * 11}${'y' * 5}daeiounc';

String stripDiacritics(String input) {
  final s = input.toLowerCase().replaceAll(RegExp(r'[\u0300-\u036f]'), ''); // dấu dạng tổ hợp
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = _from.indexOf(ch);
    b.write(i >= 0 ? _to[i] : ch);
  }
  return b.toString();
}

// ---------- So khớp mờ: chịu được OCR sai 1-2 ký tự ("WINMART" -> "WTNMART") ----------
int _lev(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      cur[j] = math.min(math.min(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1));
    }
    prev = cur;
  }
  return prev[b.length];
}

// Từ khóa ngắn phải khớp chính xác (tránh "com", "pho" khớp bừa); càng dài càng cho phép sai nhiều.
int _maxDist(String k) => k.length >= 9 ? 2 : k.length >= 6 ? 1 : 0;

bool fuzzyIncludes(String text, String key) {
  if (text.contains(key)) return true;
  final d = _maxDist(key);
  if (d == 0) return false;
  for (var len = key.length - d; len <= key.length + d; len++) {
    for (var i = 0; i + len <= text.length; i++) {
      if (_lev(text.substring(i, i + len), key) <= d) return true;
    }
  }
  return false;
}

// Số tiền kiểu VN: "47.000", "1,500,000" (nhóm 3 chữ số) hoặc 4-9 chữ số liền.
// Tối đa 9 chữ số + lookahead nên số điện thoại / số tài khoản (10+ số) KHÔNG bị nhận nhầm thành tiền.
const _amt = r'(\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?!\d)';
final _amountRe = RegExp(r'(?<!\d)' + _amt);
final _signedRe = RegExp(r'([+\-−])\s?' + _amt); // tin nhắn ngân hàng: "-150,000" / "+2,000,000"
final _dateRe = RegExp(r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)');
final _timeRe = RegExp(r'(?<!\d)\d{1,2}:\d{2}(?::\d{2})?(?!\d)');
// Số dư không phải tiền giao dịch. [^\d+\-−] dừng lại trước dấu +/- để không "nuốt" nhầm số tiền thật.
final _balanceRe = RegExp(r'(?:so du|\bsd\b)[^\d+\-−]{0,12}' + _amt);
final _bankHint = RegExp(r'so du|\bsd\b|\btk\b|chuyen khoan|giao dich|\bgd\b');
final _incomeWords = RegExp(r'nhan tien|tien vao|\bcredit\b|received|ghi co');
final _noteRe = RegExp(r'(?:\bnd|noi dung)\s*[:.]\s*'); // \b: không khớp "nd" nằm trong "VND"

const _totalKeys = ['tong cong', 'tong tien', 'thanh tien', 'thanh toan', 'tong so tien', 'so tien', 'total', 'amount'];
// Tiền khách đưa / thối lại thường LỚN hơn tổng thật nên phải loại khỏi phép "lấy số lớn nhất".
const _tenderKeys = ['khach dua', 'tien mat', 'tien thua', 'tra lai', 'cash', 'change'];

int _toInt(String s) => int.parse(s.replaceAll(RegExp(r'[.,]'), ''));
List<int> _amountsIn(String line) =>
    _amountRe.allMatches(line).map((m) => _toInt(m.group(1)!)).where((v) => v >= 1000).toList(); // bỏ số lượng/đơn giá vô nghĩa

class ReceiptParser {
  static ParsedReceipt parse(String text) {
    final raw = text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final lines = raw.map(stripDiacritics).toList();
    final all = lines.join('\n');
    // Xóa ngày, giờ, số dư trước khi tìm tiền, kẻo "2026" bị hiểu là 2.026đ.
    final cleaned = [for (final l in lines) l.replaceAll(_dateRe, ' ').replaceAll(_timeRe, ' ').replaceAll(_balanceRe, ' ')];

    int? amount;
    var income = false;
    // Ưu tiên 1: tin nhắn ngân hàng (có +/- ngay trước số tiền).
    final signed = _bankHint.hasMatch(all) ? _signedRe.firstMatch(cleaned.join('\n')) : null;
    if (signed != null) {
      amount = _toInt(signed.group(2)!);
      income = signed.group(1) == '+';
    } else {
      // Ưu tiên 2: dòng "Tổng cộng/Thanh toán". Ưu tiên 3: số lớn nhất (trừ dòng tiền khách đưa).
      amount = _fromKeywords(cleaned) ?? _maxAmount(cleaned);
      income = _incomeWords.hasMatch(all);
    }
    return ParsedReceipt(amount: amount, date: _parseDate(all), merchant: _merchant(raw, lines), isIncome: income);
  }

  static int? _fromKeywords(List<String> lines) {
    int? best;
    for (var i = 0; i < lines.length; i++) {
      if (!_totalKeys.any((k) => fuzzyIncludes(lines[i], k))) continue;
      var vals = _amountsIn(lines[i]);
      // "Tổng cộng" ở dòng trên, số tiền ở dòng dưới.
      if (vals.isEmpty && i + 1 < lines.length) vals = _amountsIn(lines[i + 1]);
      for (final v in vals) {
        if (best == null || v > best) best = v; // "Tổng tiền hàng" < "Tổng thanh toán" (có VAT)
      }
    }
    return best;
  }

  static int? _maxAmount(List<String> lines) {
    final vals = [
      for (final l in lines)
        if (!_tenderKeys.any((k) => fuzzyIncludes(l, k))) ..._amountsIn(l),
    ];
    return vals.isEmpty ? null : vals.reduce(math.max);
  }

  static DateTime? _parseDate(String t) {
    final d = _dateRe.firstMatch(t);
    if (d == null) return null;
    final day = int.parse(d.group(1)!), month = int.parse(d.group(2)!);
    var year = int.parse(d.group(3)!);
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  // Tên: ưu tiên nội dung chuyển khoản ("ND: ..."), không có thì lấy dòng đầu có chữ và không có số tiền.
  static String? _merchant(List<String> raw, List<String> lines) {
    for (var i = 0; i < raw.length; i++) {
      final m = _noteRe.firstMatch(lines[i]);
      if (m != null && m.end <= raw[i].length) {
        final n = raw[i].substring(m.end).trim();
        if (n.isNotEmpty) return n;
      }
    }
    final letter = RegExp(r'\p{L}', unicode: true);
    for (final l in raw) {
      if (letter.allMatches(l).length >= 3 && _amountsIn(stripDiacritics(l)).isEmpty && !RegExp(r'\d{4}').hasMatch(l)) return l;
    }
    return null;
  }

  // Thứ tự quan trọng: "lotte cinema" (Giải trí) phải đứng trước "lotte" (Mua sắm). Từ khóa viết KHÔNG DẤU.
  static const _rules = <String, List<String>>{
    'Ăn uống (F&B)': ['coffee', 'cafe', 'ca phe', 'tra sua', 'can tin', 'nha hang', 'quan an', 'pho', 'com', 'bun bo', 'banh mi', 'highlands', 'phuc long', 'starbucks', 'kfc', 'lotteria', 'grabfood', 'shopeefood'],
    'Học tập & Giáo trình': ['sach', 'fahasa', 'van phong pham', 'photo', 'photocopy', 'in an', 'hoc phi', 'giao trinh'],
    'Di chuyển & Xăng xe': ['xang', 'petrolimex', 'grab', 'taxi', 'gui xe', 'xanh sm', 'gojek'],
    'Giải trí & Hoạt động': ['cgv', 'lotte cinema', 'rap', 'game', 'karaoke', 'netflix', 'spotify'],
    'Mua sắm & Siêu thị': ['circle k', 'winmart', 'coopmart', 'bach hoa', 'sieu thi', 'lotte', 'gs25', 'family mart', 'big c', 'aeon', 'shopee', 'lazada'],
  };

  // (?<![\w.@]): "gmail.com" ở chân hóa đơn không bị tính là từ khóa "com".
  static bool _kw(String text, String k) =>
      RegExp(r'(?<![\w.@])' + RegExp.escape(k) + r'(?!\w)').hasMatch(text) || (k.length >= 6 && fuzzyIncludes(text, k));

  static String? _match(String text) {
    for (final e in _rules.entries) {
      for (final k in e.value) {
        if (_kw(text, k)) return e.key;
      }
    }
    return null;
  }

  /// Tên cửa hàng ưu tiên hơn tên món: xét TỪNG dòng đầu theo thứ tự (dòng 1 rồi dòng 2), cuối cùng mới xét toàn bộ.
  /// Nhờ vậy "WinMart" (dòng 1) thắng "Bánh mì" (dòng 2) dù Ăn uống đứng trước trong _rules.
  static String guessCategory(String text) {
    final lines = text.split(RegExp(r'[\r\n]+')).map((l) => stripDiacritics(l.trim())).where((l) => l.isNotEmpty).toList();
    return (lines.isNotEmpty ? _match(lines[0]) : null) ??
        (lines.length > 1 ? _match(lines[1]) : null) ??
        _match(lines.join('\n')) ??
        categories.first.name;
  }
}
