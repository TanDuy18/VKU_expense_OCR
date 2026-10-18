import 'models/expense.dart';

String vnd(int n) => '${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} đ';

Map<String, int> totalsByCategory(List<Expense> list) {
  final m = <String, int>{};
  for (final e in list) { m[e.category] = (m[e.category] ?? 0) + e.amount; }
  return m;
}

// Tổng chi theo từng ngày của tuần hiện tại: [T2, T3, ..., CN]
List<int> weekTotals(List<Expense> list, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final monday = DateTime(n.year, n.month, n.day).subtract(Duration(days: n.weekday - 1));
  final out = List.filled(7, 0);
  for (final e in list) {
    final i = DateTime(e.date.year, e.date.month, e.date.day).difference(monday).inDays;
    if (i >= 0 && i < 7) out[i] += e.amount;
  }
  return out;
}
