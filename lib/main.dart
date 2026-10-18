import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/db.dart';
import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  store.load(); // đọc SQLite khi khởi động
  runApp(MaterialApp(
    title: 'VKU Expense OCR',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const Shell(),
  ));
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Nền sáng nên biểu tượng thanh trạng thái phải tối
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VKU Expense OCR',
                        style: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800))
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [HomeScreen(), HistoryScreen(), AnalysisScreen()],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Lịch sử'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Phân tích'),
          ],
        ),
      ),
    );
  }
}
