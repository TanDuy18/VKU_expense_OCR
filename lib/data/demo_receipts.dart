class DemoReceipt {
  final String title, ocrText;
  final int amount; // số tiền đúng, dùng để hiển thị và kiểm thử
  const DemoReceipt(this.title, this.amount, this.ocrText);
}

String _today() {
  final d = DateTime.now();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// Văn bản giống kết quả OCR thật, đi qua cùng bộ regex với ảnh chụp
List<DemoReceipt> demoReceipts() => [
      DemoReceipt('Highlands Coffee - Khu V', 122000,
          'HIGHLANDS COFFEE - KHU V\n${_today()}\n2 x Phin Sữa Đá 58.000\n2 x Bánh mì 64.000\nTổng cộng: 122.000đ'),
      DemoReceipt('Căn tin Khu V - VKU', 40000,
          'CĂN TIN KHU V - VKU\n${_today()}\nCơm sườn 35.000\nNước suối 5.000\nTổng cộng: 40.000đ'),
      DemoReceipt('Nhà sách Fahasa', 200000,
          'NHÀ SÁCH FAHASA ĐÀ NẴNG\n${_today()}\nGiáo trình Cấu trúc dữ liệu 150.000\nVở kẻ ngang 50.000\nTổng cộng: 200.000đ'),
    ];
