import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/db.dart';
import '../stats.dart';
import '../widgets.dart';
import 'review_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _scan(BuildContext context, ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600); // thu nhỏ ảnh để OCR nhanh
    if (x == null || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(imagePath: x.path)));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          FilledButton.icon(onPressed: () => _scan(context, ImageSource.camera), icon: const Icon(Icons.camera_alt),
              label: const Text('QUÉT HÓA ĐƠN MỚI (ON-DEVICE OCR)'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(18))),
          TextButton(onPressed: () => _scan(context, ImageSource.gallery), child: const Text('Hoặc chọn ảnh từ thư viện')),
          Panel(title: 'Cơ cấu chi tiêu', child: DonutChart(totals: totalsByCategory(store.items))),
          Panel(title: 'Chi tiêu 7 ngày qua', child: WeeklyBars(values: weekTotals(store.items))),
          const Text('Giao dịch gần đây', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (store.items.isEmpty) const Text('Chưa có giao dịch. Bấm quét hóa đơn để bắt đầu.'),
          for (final e in store.items.take(6)) TxTile(e),
        ]),
      );
}
