import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../data/db.dart';
import '../models/expense.dart';
import '../ocr/ocr_service.dart';
import '../parser/receipt_parser.dart';

// Màn hình xác nhận: OCR (hoặc văn bản mẫu) → regex điền sẵn → sửa → lưu SQLite
class ReviewScreen extends StatefulWidget {
  final String? imagePath; // ảnh chụp/chọn
  final String? demoText;  // văn bản mẫu, bỏ qua bước OCR
  const ReviewScreen({super.key, this.imagePath, this.demoText});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _ocr = OcrService();
  final _merchant = TextEditingController(), _amount = TextEditingController();
  DateTime _date = DateTime.now();
  String _cat = categories.first.name, _raw = '';
  bool _loading = true;

  @override
  void initState() { super.initState(); _run(); }

  Future<void> _run() async {
    try {
      _raw = widget.demoText ?? await _ocr.read(widget.imagePath!);
      final p = ReceiptParser.parse(_raw);
      _merchant.text = p.merchant ?? '';
      _amount.text = p.amount?.toString() ?? '';
      _date = p.date ?? _date;
      _cat = ReceiptParser.guessCategory(_raw);
    } catch (e) {
      _raw = 'Không đọc được ảnh, hãy nhập tay. ($e)';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final amt = int.tryParse(_amount.text.replaceAll(RegExp(r'[.,\s]'), ''));
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số tiền lớn hơn 0')));
      return;
    }
    String? saved;
    if (widget.imagePath != null) {
      // Chép ảnh vào thư mục riêng của app để xem lại sau này
      final dir = await getApplicationDocumentsDirectory();
      saved = (await File(widget.imagePath!).copy('${dir.path}/rcpt_${DateTime.now().millisecondsSinceEpoch}.jpg')).path;
    }
    await store.add(Expense(merchant: _merchant.text.trim(), amount: amt, date: _date, category: _cat, imagePath: saved));
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst); // về trang chủ
  }

  @override
  void dispose() { _ocr.dispose(); _merchant.dispose(); _amount.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kiểm tra hóa đơn')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(16), children: [
                if (widget.imagePath != null) ...[
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(widget.imagePath!), height: 170, fit: BoxFit.cover)),
                  const SizedBox(height: 12),
                ],
                TextField(controller: _merchant, decoration: const InputDecoration(labelText: 'Cửa hàng', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số tiền (đ)', border: OutlineInputBorder())),
                ListTile(contentPadding: EdgeInsets.zero, title: Text('Ngày: ${_date.toIso8601String().substring(0, 10)}'), trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setState(() => _date = d);
                  }),
                DropdownButtonFormField<String>(value: _cat, decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
                  items: [for (final c in categories) DropdownMenuItem(value: c.name, child: Text('${c.emoji} ${c.name}'))],
                  onChanged: (v) => setState(() => _cat = v ?? _cat)),
                ExpansionTile(title: const Text('Văn bản OCR gốc'), children: [Padding(padding: const EdgeInsets.all(8), child: Text(_raw))]),
                const SizedBox(height: 8),
                FilledButton(onPressed: _save, style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)), child: const Text('Lưu giao dịch')),
              ]),
      );
}
