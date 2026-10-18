import 'package:flutter/material.dart';
import '../data/db.dart';
import '../models/expense.dart';
import '../stats.dart';
import '../widgets.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final totals = totalsByCategory(store.items);
          final sum = totals.values.fold<int>(0, (a, b) => a + b);
          final rows = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return ListView(padding: const EdgeInsets.all(16), children: [
            Panel(title: '🏆 Bảng phân bổ ngân sách', child: sum == 0
                ? const Text('Chưa có dữ liệu để phân tích.')
                : Column(children: [for (final e in rows) Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: [
                    Row(children: [Expanded(child: Text('${categoryOf(e.key).emoji} ${e.key}')),
                      Text('${vnd(e.value)} (${(e.value * 100 / sum).toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.w700))]),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: e.value / sum, minHeight: 6, color: categoryOf(e.key).color, backgroundColor: const Color(0xFFE2E8F0))]))])),
          ]);
        },
      );
}
