import 'package:flutter_test/flutter_test.dart';
import '../lib/parser/receipt_parser.dart';

void main() {
  test('stripDiacritics bỏ dấu tiếng Việt', () {
    expect(stripDiacritics('Tổng Cộng Đồng'), 'tong cong dong');
  });

  group('hóa đơn siêu thị', () {
    final r = ReceiptParser.parse('WINMART\n123 Nguyen Trai\n18/10/2026 19:05\n'
        'Sua tuoi 32.000\nBanh mi 15.000\nTong cong 47.000\nTien khach dua 50.000');
    test('lấy dòng Tổng cộng, không lấy tiền khách đưa', () => expect(r.amount, 47000));
    test('ngày', () => expect(r.date, DateTime(2026, 10, 18)));
    test('tên cửa hàng', () => expect(r.merchant, 'WINMART'));
    test('danh mục', () => expect(ReceiptParser.guessCategory('WINMART\nBanh mi 15.000'), 'Mua sắm & Siêu thị'));
  });

  // Nguyên văn đầu ra OCR thật: "WINMART" -> "WTNMART", "Tổng cộng" -> "Tôäg cộng", "Tiền khách" -> "Tiêh khách"
  group('chịu được lỗi OCR thật', () {
    const ocr = 'WTNMART\n\n123 Nguyêñ Trãi, Quận 1\n18/10/2026 19:05\n\nSữa tươi 32.000\nBánh mì 15.000\nTôäg cộng 47.000\nTiêh khách đưa 50.000';
    test('vẫn nhận dòng tổng dù sai chữ', () => expect(ReceiptParser.parse(ocr).amount, 47000));
    test('vẫn phân loại đúng nhờ khớp mờ tên cửa hàng', () => expect(ReceiptParser.guessCategory(ocr), 'Mua sắm & Siêu thị'));
    test('không có dòng tổng: bỏ qua tiền khách đưa', () {
      expect(ReceiptParser.parse('Sua 32.000\nBanh mi 15.000\nTien khach dua 100.000').amount, 32000);
    });
  });

  test('có dấu tiếng Việt và đuôi "đ"', () {
    expect(ReceiptParser.parse('Cà phê Highlands\nTổng cộng: 150.000đ').amount, 150000);
  });

  test('số điện thoại không bị nhận thành tiền', () {
    final r = ReceiptParser.parse('Hotline 0901234567\nGrab\nThanh toan 45,000 VND');
    expect(r.amount, 45000);
    expect(ReceiptParser.guessCategory('Hotline 0901234567\nGrab'), 'Di chuyển & Xăng xe');
  });

  test('năm trong ngày không bị nhận thành tiền', () {
    expect(ReceiptParser.parse('18/10/2026 hoa don').amount, isNull);
  });

  group('tin nhắn ngân hàng', () {
    test('chi tiền (dấu -)', () {
      final r = ReceiptParser.parse('VCB 18/10/2026 12:30 So du TK 0011*** -150,000 VND. ND: ca phe highlands');
      expect(r.amount, 150000);
      expect(r.isIncome, false);
      expect(r.merchant, 'ca phe highlands');
      expect(r.date, DateTime(2026, 10, 18));
    });
    test('nhận tiền (dấu +) -> isIncome, không lấy số dư', () {
      final r = ReceiptParser.parse('TK 0011*** +2,000,000 VND luc 10:00 18/10/2026. So du 5,000,000. ND: luong thang 10');
      expect(r.amount, 2000000);
      expect(r.isIncome, true);
      expect(r.merchant, 'luong thang 10');
    });
    test('không có dấu: loại số dư khỏi phép lấy số lớn nhất', () {
      expect(ReceiptParser.parse('GD 200,000 VND. So du 5,000,000').amount, 200000);
    });
  });

  test('không có số tiền -> null', () => expect(ReceiptParser.parse('Cam on quy khach').amount, isNull));

  test('Lotte Cinema là Giải trí, Lotte Mart là Mua sắm', () {
    expect(ReceiptParser.guessCategory('Lotte Cinema Da Nang'), 'Giải trí & Hoạt động');
    expect(ReceiptParser.guessCategory('Lotte Mart Da Nang'), 'Mua sắm & Siêu thị');
  });
}
