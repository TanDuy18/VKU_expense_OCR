import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/db.dart';
import '../models/expense.dart';
import '../ocr/ocr_service.dart';
import '../parser/receipt_parser.dart';
import '../theme.dart';

/// Màn xác nhận: OCR (hoặc văn bản mẫu) → ReceiptParser → người dùng sửa lại → lưu SQLite.
/// Truyền `image` khi chụp/chọn ảnh, hoặc `demoText` khi bấm mẫu hóa đơn.
class ReviewScreen extends StatefulWidget {
  final XFile? image;
  final String? demoText;
  const ReviewScreen({super.key, this.image, this.demoText});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _rawCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = categories.first.name;
  bool _income = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _process();
  }

  @override
  void dispose() {
    _rawCtrl.dispose();
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    var text = widget.demoText ?? '';
    if (widget.image != null) {
      if (kIsWeb) {
        _error = 'Web không chạy được ML Kit. Hãy dán văn bản hóa đơn vào ô bên dưới rồi bấm "Phân tích lại".';
      } else {
        final ocr = OcrService();
        try {
          text = await ocr.read(widget.image!.path);
        } catch (e) {
          _error = 'Không đọc được ảnh ($e). Bạn có thể nhập tay bên dưới.';
        } finally {
          ocr.dispose();
        }
      }
    }
    if (!mounted) return;
    _rawCtrl.text = text;
    _applyParse();
    setState(() => _loading = false);
  }

  // Đọc lại văn bản trong ô OCR và điền vào các trường bên dưới.
  void _applyParse() {
    final text = _rawCtrl.text;
    final r = ReceiptParser.parse(text);
    _merchantCtrl.text = r.merchant ?? '';
    _amountCtrl.text = r.amount?.toString() ?? '';
    _date = r.date ?? DateTime.now();
    _income = r.isIncome;
    _category = ReceiptParser.guessCategory(text);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Hãy nhập số tiền hợp lệ')));
      return;
    }
    await store.add(Expense(
      merchant: _merchantCtrl.text.trim(),
      amount: amount,
      date: _date,
      category: _category,
      imagePath: kIsWeb ? null : widget.image?.path,
    ));
    nav.popUntil((r) => r.isFirst); // về Trang chủ
    messenger.showSnackBar(const SnackBar(content: Text('Đã lưu giao dịch')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận hóa đơn')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (!kIsWeb && widget.image != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(widget.image!.path), height: 160, fit: BoxFit.cover),
                  ),
                ),
              if (_error != null) _banner(_error!, const Color(0xFFFFF3CD)),
              if (_income)
                _banner('Có vẻ đây là tin nhắn tiền vào. App chỉ theo dõi chi tiêu, hãy kiểm tra lại trước khi lưu.',
                    const Color(0xFFFFE3E3)),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
                decoration: const InputDecoration(labelText: 'Số tiền (VND)', suffixText: 'đ'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _merchantCtrl,
                decoration: const InputDecoration(labelText: 'Cửa hàng / nội dung'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày'),
                subtitle: Text(_date.toIso8601String().substring(0, 10)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final c in categories)
                  ChoiceChip(
                    label: Text('${c.emoji} ${c.short}'),
                    selected: _category == c.name,
                    onSelected: (_) => setState(() => _category = c.name),
                  ),
              ]),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: kIsWeb,
                title: const Text('Văn bản OCR', style: TextStyle(fontWeight: FontWeight.w700)),
                children: [
                  TextField(
                    controller: _rawCtrl,
                    maxLines: 8,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(_applyParse),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Phân tích lại'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_income ? 'Vẫn lưu' : 'Lưu giao dịch'),
              ),
            ]),
    );
  }

  Widget _banner(String text, Color bg) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
      );
}
