import '../models/expense.dart';
import '../stats.dart';

/// Gợi ý tiết kiệm bằng luật: tính trực tiếp trên dữ liệu SQLite, không cần mạng, không cần API key.
/// Thay cho Gemini. Hàm thuần nên test được không cần UI.
List<String> localAdvice(List<Expense> items, [DateTime? now]) {
  final n = now ?? DateTime.now();
  if (items.isEmpty) return ['Chưa có dữ liệu chi tiêu. Hãy quét vài hóa đơn để nhận gợi ý.'];

  final out = <String>[];
  final totals = totalsByCategory(items);
  final sum = totals.values.fold<int>(0, (a, b) => a + b);
  double share(Category c) => (totals[c.name] ?? 0) * 100 / sum;

  // 1) Nhóm chi lớn nhất
  final top = totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
  final topPct = (top.value * 100 / sum).round();
  if (topPct >= 40) {
    out.add('"${categoryOf(top.key).short}" chiếm $topPct% tổng chi (${vnd(top.value)}). Thử đặt trần ngân sách riêng cho nhóm này.');
  }

  // 2) Biến động tuần này so với tuần trước
  int weekSum(DateTime d) => weekTotals(items, d).fold(0, (a, b) => a + b);
  final thisWeek = weekSum(n), lastWeek = weekSum(n.subtract(const Duration(days: 7)));
  if (lastWeek > 0 && thisWeek > lastWeek * 1.2) {
    out.add('Tuần này chi tăng ${((thisWeek - lastWeek) * 100 / lastWeek).round()}% so với tuần trước. Xem lại các khoản lớn gần đây.');
  } else if (lastWeek > 0 && thisWeek < lastWeek * 0.8) {
    out.add('Tuần này chi giảm ${((lastWeek - thisWeek) * 100 / lastWeek).round()}% so với tuần trước. Tiếp tục phát huy!');
  }

  // 3) Dự báo cuối tháng theo nhịp chi hiện tại
  final month = items.where((e) => e.date.year == n.year && e.date.month == n.month).toList();
  final monthSum = month.fold<int>(0, (a, e) => a + e.amount);
  if (monthSum > 0) {
    final daysInMonth = DateTime(n.year, n.month + 1, 0).day;
    final avg = monthSum / n.day;
    out.add('Trung bình ${vnd(avg.round())}/ngày. Giữ nhịp này, cả tháng khoảng ${vnd((avg * daysInMonth).round())}.');
    final big = month.reduce((a, b) => a.amount >= b.amount ? a : b);
    out.add('Khoản lớn nhất tháng này: ${big.merchant.isEmpty ? categoryOf(big.category).short : big.merchant} (${vnd(big.amount)}).');
  }

  // 4) Gợi ý theo từng nhóm (theo thứ tự categories trong models/expense.dart)
  if (share(categories[0]) >= 35) out.add('Ăn uống trên 35% tổng chi: ưu tiên căn tin, mang cơm hoặc nấu ăn vài bữa mỗi tuần.');
  if (share(categories[2]) >= 25) out.add('Di chuyển trên 25%: cân nhắc đi chung xe hoặc xe buýt cho các tuyến quen.');
  if (share(categories[3]) >= 25) out.add('Mua sắm trên 25%: áp dụng quy tắc chờ 24 giờ trước khi mua món không thiết yếu.');
  if (share(categories[4]) >= 20) out.add('Giải trí trên 20%: đặt hạn mức hằng tháng và tận dụng ưu đãi sinh viên.');

  out.add('Quy tắc 50/30/20: 50% nhu cầu thiết yếu, 30% mong muốn, 20% tiết kiệm.');
  return out;
}
