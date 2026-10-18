import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../ai/gemini_service.dart';
import '../data/db.dart';
import '../stats.dart';
import '../theme.dart';
import '../widgets.dart';

class AdvicePanel extends StatefulWidget {
  const AdvicePanel({super.key});
  @override
  State<AdvicePanel> createState() => _AdvicePanelState();
}

class _AdvicePanelState extends State<AdvicePanel> {
  String? _text, _updated, _error;
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadSaved(); }

  // Mở màn hình là hiện ngay gợi ý đã lưu, không cần mạng
  Future<void> _loadSaved() async {
    final r = await AppDb.loadAdvice();
    if (r != null && mounted) setState(() { _text = r['text'] as String; _updated = (r['updated'] as String).substring(0, 10); });
  }

  Future<void> _ask() async {
    setState(() { _loading = true; _error = null; });
    try {
      final t = await GeminiService.advise(totalsByCategory(store.items));
      await AppDb.saveAdvice(t);
      if (mounted) setState(() { _text = t; _updated = DateTime.now().toIso8601String().substring(0, 10); });
    } catch (e) {
      // Offline hoặc lỗi: giữ nguyên gợi ý cũ, chỉ báo lý do
      final offline = e is SocketException || e is TimeoutException || e is HandshakeException;
      if (mounted) setState(() => _error = offline ? 'Không có mạng, đang hiển thị gợi ý đã lưu.' : e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store, // dữ liệu tải xong hoặc có giao dịch mới thì dựng lại, nút tự mở khóa
        builder: (context, _) => Panel(
          title: 'Gợi ý tiết kiệm (Gemini)',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_text != null) ...[
              Text(_text!, style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text('Cập nhật $_updated', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ] else
              Text('Chưa có gợi ý. Cần mạng cho lần phân tích đầu tiên.', style: TextStyle(color: AppColors.muted)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFB3261E))),
              ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: (_loading || store.items.isEmpty) ? null : _ask,
              child: Text(_loading ? 'Đang phân tích…' : 'Phân tích chi tiêu'),
            ),
          ]),
        ),
      );
}
