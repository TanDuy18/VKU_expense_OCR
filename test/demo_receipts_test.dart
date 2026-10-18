import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/data/demo_receipts.dart';
import 'package:vku_expense_ocr/parser/receipt_parser.dart';

void main() {
  test('3 hóa đơn mẫu parse đúng số tiền', () {
    for (final d in demoReceipts()) {
      expect(ReceiptParser.parse(d.ocrText).amount, d.amount, reason: d.title);
    }
  });
}
