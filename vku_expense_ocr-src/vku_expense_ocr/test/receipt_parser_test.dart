import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/parser/receipt_parser.dart';
import 'package:vku_expense_ocr/stats.dart';

void main() {
  group('ReceiptParser', () {
    test('hóa đơn có dòng Tổng cộng', () {
      final r = ReceiptParser.parse('HIGHLANDS COFFEE - KHU V\n08/10/2026\nTổng cộng: 122.000đ');
      expect(r.amount, 122000);
      expect(r.date, DateTime(2026, 10, 8));
      expect(r.merchant, 'HIGHLANDS COFFEE - KHU V');
    });
    test('không có Tổng cộng → lấy số tiền lớn nhất', () {
      expect(ReceiptParser.parse('Cua hang A\n50,000 VND\n150,000 VND').amount, 150000);
    });
    test('không có số tiền → null', () => expect(ReceiptParser.parse('xin chào').amount, isNull));
    test('đoán danh mục', () => expect(ReceiptParser.guessCategory('Nhà sách Fahasa'), 'Học tập & Giáo trình'));
  });
  group('stats', () {
    test('định dạng VND', () => expect(vnd(1250000), '1.250.000 đ'));
    test('tổng theo tuần (T2..CN)', () {
      final e = (int a, DateTime d) => Expense(merchant: '', amount: a, category: 'x', date: d);
      final r = weekTotals([e(5, DateTime(2026, 10, 12)), e(7, DateTime(2026, 10, 18)), e(9, DateTime(2026, 10, 11))], DateTime(2026, 10, 18));
      expect(r, [5, 0, 0, 0, 0, 0, 7]); // 11/10 là tuần trước nên bị bỏ
    });
  });
}
