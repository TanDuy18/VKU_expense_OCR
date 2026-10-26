import 'package:flutter_test/flutter_test.dart';
import '../lib/advice/local_advisor.dart';
import '../lib/models/expense.dart';

Expense e(int amount, int cat, DateTime d) =>
    Expense(merchant: 'x', amount: amount, category: categories[cat].name, date: d);

void main() {
  final now = DateTime(2026, 10, 21); // Thứ Tư; tuần này bắt đầu 19/10, tuần trước 12-18/10

  test('chưa có dữ liệu', () => expect(localAdvice([], now).single, contains('Chưa có')));

  test('cảnh báo nhóm chiếm >= 40% và có dự báo cuối tháng', () {
    final tips = localAdvice([e(600000, 0, DateTime(2026, 10, 5)), e(400000, 1, DateTime(2026, 10, 6))], now);
    expect(tips.any((t) => t.contains('Ăn uống') && t.contains('60%')), true);
    expect(tips.any((t) => t.contains('cả tháng khoảng')), true);
  });

  test('tuần này chi tăng > 20% so với tuần trước', () {
    final tips = localAdvice([e(100000, 0, DateTime(2026, 10, 14)), e(130000, 0, DateTime(2026, 10, 20))], now);
    expect(tips.any((t) => t.contains('tăng 30%')), true);
  });

  test('tuần này chi giảm > 20%', () {
    final tips = localAdvice([e(100000, 0, DateTime(2026, 10, 14)), e(50000, 0, DateTime(2026, 10, 20))], now);
    expect(tips.any((t) => t.contains('giảm 50%')), true);
  });
}
