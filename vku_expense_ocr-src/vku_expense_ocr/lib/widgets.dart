import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'stats.dart';

class Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const Panel({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext c) => Card(
        elevation: 0, margin: const EdgeInsets.only(bottom: 14), color: Colors.white,
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12), child])));
}

class TxTile extends StatelessWidget {
  final Expense e;
  const TxTile(this.e, {super.key});
  @override
  Widget build(BuildContext c) {
    final cat = categoryOf(e.category);
    return Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: cat.color.withAlpha(30), child: Text(cat.emoji)),
        title: Text(e.merchant.isEmpty ? cat.name : e.merchant, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(e.date.toIso8601String().substring(0, 10)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(vnd(e.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(cat.name, style: TextStyle(fontSize: 11, color: cat.color))])));
  }
}

void _label(Canvas c, String s, Offset center, {double size = 10, bool bold = false}) {
  final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(color: const Color(0xFF334155), fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)), textDirection: TextDirection.ltr)..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

// ---- Donut: vẽ trực tiếp bằng Canvas, không dùng thư viện biểu đồ ----
class DonutPainter extends CustomPainter {
  final Map<String, int> totals;
  final double progress; // 0→1, dùng cho hiệu ứng animation
  DonutPainter(this.totals, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 28.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: math.min(size.width, size.height) / 2 - stroke / 2);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke;
    final sum = totals.values.fold<int>(0, (a, b) => a + b);
    if (sum == 0) { canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = const Color(0xFFE2E8F0)); return; }
    var start = -math.pi / 2; // bắt đầu từ 12 giờ
    for (final e in totals.entries) {
      final sweep = e.value / sum * 2 * math.pi * progress;
      canvas.drawArc(rect, start, sweep, false, paint..color = categoryOf(e.key).color);
      start += sweep;
    }
  }
  @override
  bool shouldRepaint(DonutPainter o) => o.progress != progress || o.totals != totals;
}

class DonutChart extends StatelessWidget {
  final Map<String, int> totals;
  const DonutChart({super.key, required this.totals});
  @override
  Widget build(BuildContext c) {
    final sum = totals.values.fold<int>(0, (a, b) => a + b);
    return Column(children: [
      SizedBox(height: 190, child: TweenAnimationBuilder<double>(
        key: ValueKey(sum), tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
        builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size.square(190), painter: DonutPainter(totals, v)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Tổng chi tiêu', style: TextStyle(fontSize: 11, color: Colors.black54)),
            Text(vnd(sum), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))])]))),
      const SizedBox(height: 10),
      Wrap(spacing: 12, runSpacing: 4, children: [for (final e in totals.entries)
        Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 4, backgroundColor: categoryOf(e.key).color), const SizedBox(width: 4),
          Text('${e.key}: ${(e.value * 100 / sum).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11))])]),
    ]);
  }
}

// ---- Biểu đồ cột 7 ngày ----
class BarPainter extends CustomPainter {
  final List<int> values;
  final double progress;
  BarPainter(this.values, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 24.0, topH = 16.0;
    final maxV = math.max(1, values.reduce(math.max));
    final w = size.width / 7, chartH = size.height - labelH - topH;
    final paint = Paint()..color = const Color(0xFF2563EB);
    for (var i = 0; i < 7; i++) {
      final h = values[i] / maxV * chartH * progress;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i * w + w * 0.2, size.height - labelH - h, w * 0.6, h), const Radius.circular(6)), paint);
      _label(canvas, i == 6 ? 'CN' : 'T${i + 2}', Offset(i * w + w / 2, size.height - 10));
      if (values[i] > 0 && progress > .95) _label(canvas, '${(values[i] / 1000).round()}k', Offset(i * w + w / 2, size.height - labelH - h - 8), size: 9, bold: true);
    }
  }
  @override
  bool shouldRepaint(BarPainter o) => o.progress != progress || o.values != values;
}

class WeeklyBars extends StatelessWidget {
  final List<int> values;
  const WeeklyBars({super.key, required this.values});
  @override
  Widget build(BuildContext c) => SizedBox(height: 170, child: TweenAnimationBuilder<double>(
        key: ValueKey(values.join(',')), tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(size: Size.infinite, painter: BarPainter(values, v))));
}
