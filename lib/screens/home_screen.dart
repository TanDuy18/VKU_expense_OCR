import 'package:flutter/material.dart';
import '../data/db.dart';
import '../stats.dart';
import '../theme.dart';
import '../widgets.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text('Tháng này bạn đã chi', style: TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 4),
          // Số tổng to ở đầu trang để nhìn là biết ngay
          Text(vnd(monthTotal(store.items)),
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Quét hóa đơn mới'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 36),
          Panel(title: 'Cơ cấu chi tiêu', child: DonutChart(totals: totalsByCategory(store.items))),
          Panel(title: 'Chi tiêu 7 ngày qua', child: WeeklyBars(values: weekTotals(store.items))),
          const Text('Giao dịch gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          for (final e in store.items.take(6)) TxTile(e),
        ],
      ),
    );
  }
}
