import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/demo_receipts.dart';
import '../stats.dart';
import 'review_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Future<void> _pick(BuildContext context, ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85); // thu nhỏ để OCR nhanh
    if (x == null || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(image: x)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Quét hóa đơn (Google ML Kit)')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            height: 180,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue, width: 2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.receipt_long, size: 52, color: Colors.blueGrey),
              const SizedBox(height: 8),
              const Text('Đặt hóa đơn vào trong khung', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  kIsWeb ? 'Web: ML Kit chỉ chạy trên điện thoại. Hãy dán văn bản ở bước sau hoặc dùng mẫu bên dưới'
                         : 'Nhận dạng văn bản trên máy, không cần Internet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: () => _pick(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt), label: const Text('Chụp Camera'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.tonalIcon(
              onPressed: () => _pick(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library), label: const Text('Chọn Ảnh'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
          ]),
          const SizedBox(height: 24),
          const Text('⚡ Thử nghiệm mẫu hóa đơn nhanh (Demo Test)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final d in demoReceipts())
            Card(
              elevation: 0, color: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: const CircleAvatar(child: Icon(Icons.receipt)),
                title: Text('${d.title} (${vnd(d.amount)})', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Bấm để quét nhận dạng thử'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(demoText: d.ocrText))),
              ),
            ),
        ]),
      );
}
