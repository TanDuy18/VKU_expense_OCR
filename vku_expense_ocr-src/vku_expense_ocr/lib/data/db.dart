import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class AppDb {
  static Database? _db;
  static Future<Database> get db async => _db ??= await openDatabase(
        p.join(await getDatabasesPath(), 'expense.db'),
        version: 1,
        onCreate: (d, v) => d.execute('CREATE TABLE expenses('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, merchant TEXT, amount INTEGER NOT NULL, '
            'date TEXT NOT NULL, category TEXT, image_path TEXT)'),
      );
  static Future<void> insert(Expense e) async => (await db).insert('expenses', e.toMap());
  static Future<List<Expense>> all() async {
    final rows = await (await db).query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }
}

// Store đơn giản: màn hình lắng nghe (ListenableBuilder) và tự vẽ lại khi dữ liệu đổi
class ExpenseStore extends ChangeNotifier {
  List<Expense> items = [];
  Future<void> load() async { items = await AppDb.all(); notifyListeners(); }
  Future<void> add(Expense e) async { await AppDb.insert(e); await load(); }

  // Chỉ để demo: thêm vài giao dịch mẫu khi bảng còn trống
  Future<void> seedDemo() async {
    if (items.isNotEmpty) return;
    final now = DateTime.now();
    const demo = [
      ['Highlands Coffee - Khu V', 122000, 0], ['Nhà sách Fahasa Đà Nẵng', 200000, 1],
      ['Căn tin Khu V - Đại học VKU', 40000, 0], ['Circle K Nam Kỳ Khởi Nghĩa', 46000, 3],
      ['Cây xăng Petrolimex Hòa Khánh', 70000, 2], ['Rạp CGV Vincom Đà Nẵng', 150000, 4],
    ];
    for (var i = 0; i < demo.length; i++) {
      await AppDb.insert(Expense(merchant: demo[i][0] as String, amount: demo[i][1] as int,
          category: categories[demo[i][2] as int].name, date: now.subtract(Duration(days: i))));
    }
    await load();
  }
}
final store = ExpenseStore();
