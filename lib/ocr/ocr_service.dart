import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// OCR chạy hoàn toàn trên máy (không cần mạng, không tốn phí cloud)
class OcrService {
  // Bộ nhận dạng Latin: đọc tốt số và chữ không dấu, dấu tiếng Việt có thể sai
  // → logic regex ưu tiên số tiền/ngày để không phụ thuộc dấu.
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  Future<String> read(String path) async =>
      (await _recognizer.processImage(InputImage.fromFilePath(path))).text;
  void dispose() => _recognizer.close();
}
