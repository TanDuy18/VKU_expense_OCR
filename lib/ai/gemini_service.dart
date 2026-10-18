import 'dart:convert';
import 'package:http/http.dart' as http;

// Key KHÔNG viết trong code. Truyền lúc chạy: --dart-define-from-file=env.json
const _key = String.fromEnvironment('GEMINI_KEY');
// Tên model đổi rất nhanh: có thể đổi bằng "GEMINI_MODEL" trong env.json
const _model = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.5-flash');
// Model dự phòng khi model chính quá tải. Tên này trỏ tới bản Flash hiện hành.
const _fallbackModel = 'gemini-flash-latest';

class GeminiService {
  static bool get hasKey => _key.isNotEmpty;

  // Chỉ gửi tổng theo danh mục. Không gửi ảnh hóa đơn, tên cửa hàng hay văn bản OCR (riêng tư).
  static String buildPrompt(Map<String, int> totals) {
    final lines = totals.entries.map((e) => '- ${e.key}: ${e.value} VND').join('\n');
    return 'Bạn là trợ lý tài chính cho sinh viên. Dưới đây là tổng chi theo danh mục:\n$lines\n'
        'Hãy nêu 3 khoản đáng chú ý và 3 gợi ý tiết kiệm cụ thể, ngắn gọn, bằng tiếng Việt. '
        'Trả lời bằng văn bản thuần, không dùng markdown.';
  }

  // Lỗi tạm thời: đáng thử lại. Các lỗi khác (400 sai key, 404 sai model) thử lại vô ích.
  static const _temporary = [429, 500, 503, 504];

  static Future<String> advise(Map<String, int> totals) async {
    if (!hasKey) throw Exception('Chưa có GEMINI_KEY (xem hướng dẫn chạy)');
    final models = {_model, _fallbackModel}.toList(); // Set để không trùng nhau
    int? lastStatus;

    for (final m in models) {
      for (var attempt = 0; attempt < 2; attempt++) {
        final res = await http
            .post(
              Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent'),
              headers: {'Content-Type': 'application/json', 'x-goog-api-key': _key},
              body: jsonEncode({
                'contents': [
                  {'parts': [{'text': buildPrompt(totals)}]}
                ]
              }),
            )
            .timeout(const Duration(seconds: 15)); // offline hoặc mạng yếu sẽ ném lỗi, UI xử lý

        if (res.statusCode == 200) {
          // Model đời mới có thể trả nhiều phần, nối hết lại
          final parts = jsonDecode(res.body)['candidates'][0]['content']['parts'] as List;
          return parts.map((p) => (p['text'] ?? '') as String).join();
        }
        lastStatus = res.statusCode;
        if (!_temporary.contains(res.statusCode)) break; // lỗi vĩnh viễn: bỏ qua, sang model khác
        await Future.delayed(const Duration(seconds: 2)); // chờ một chút rồi thử lại
      }
    }
    throw Exception(lastStatus == 503
        ? 'Gemini đang quá tải, hãy thử lại sau ít phút.'
        : 'Gemini trả về lỗi $lastStatus');
  }
}
