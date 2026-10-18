import 'package:flutter/material.dart';
import 'data/db.dart';
import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';

const navy = Color(0xFF1E3A5F);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  store.load(); // đọc SQLite khi khởi động
  runApp(MaterialApp(
    title: 'VKU Expense OCR', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: navy, scaffoldBackgroundColor: const Color(0xFFF1F4F9)),
    home: const Shell()));
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Container(width: double.infinity, color: navy,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 8, 14),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('VKU Expense OCR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Từ Thị Thanh Hương — 23IT117 (23JIT)', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11))])),
              IconButton(tooltip: 'Thêm dữ liệu mẫu', icon: const Icon(Icons.dataset, color: Colors.white), onPressed: store.seedDemo),
            ])),
          Expanded(child: IndexedStack(index: _tab, children: const [HomeScreen(), HistoryScreen(), AnalysisScreen()])),
        ]),
        bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (i) => setState(() => _tab = i), destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Lịch sử'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Phân tích')]),
      );
}
