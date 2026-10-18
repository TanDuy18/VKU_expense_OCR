import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class AppDb {
  static Database? _db;

  static const _expensesSql = 'CREATE TABLE expenses('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, merchant TEXT, amount INTEGER NOT NULL, '
      'date TEXT NOT NULL, category TEXT, image_path TEXT)';
  // Chỉ có đúng 1 dòng (id = 1): gợi ý Gemini gần nhất
  static const _adviceSql = 'CREATE TABLE IF NOT EXISTS advice('
      'id INTEGER PRIMARY KEY, text TEXT NOT NULL, updated TEXT NOT NULL)';

  static Future<Database> get db async => _db ??= await openDatabase(
        p.join(await getDatabasesPath(), 'expense.db'),
        version: 2,
        onCreate: (d, v) async {
          await d.execute(_expensesSql);
          await d.execute(_adviceSql);
          await _seed(d); // chỉ chạy 1 lần, lúc database được tạo
        },
        // Database version 1 cũ → thêm bảng advice, giữ nguyên dữ liệu
        onUpgrade: (d, oldV, newV) async {
          if (oldV < 2) await d.execute(_adviceSql);
        },
      );

  static Future<void> _seed(Database d) async {
    final now = DateTime.now();
    const demo = [
      ['Highlands Coffee - Khu V', 122000, 0], ['Nhà sách Fahasa Đà Nẵng', 200000, 1],
      ['Căn tin Khu V - Đại học VKU', 40000, 0], ['Circle K Nam Kỳ Khởi Nghĩa', 46000, 3],
      ['Cây xăng Petrolimex Hòa Khánh', 70000, 2], ['Rạp CGV Vincom Đà Nẵng', 150000, 4],
    ];
    final batch = d.batch();
    for (var i = 0; i < demo.length; i++) {
      batch.insert('expenses', Expense(
        merchant: demo[i][0] as String, amount: demo[i][1] as int,
        category: categories[demo[i][2] as int].name, date: now.subtract(Duration(days: i)),
      ).toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<void> insert(Expense e) async => (await db).insert('expenses', e.toMap());
  static Future<List<Expense>> all() async {
    final rows = await (await db).query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  // Lưu/đọc gợi ý Gemini để xem lại khi offline
  static Future<void> saveAdvice(String text) async => (await db).insert(
      'advice', {'id': 1, 'text': text, 'updated': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace);
  static Future<Map<String, Object?>?> loadAdvice() async {
    final r = await (await db).query('advice', where: 'id = 1');
    return r.isEmpty ? null : r.first;
  }
}

class ExpenseStore extends ChangeNotifier {
  List<Expense> items = [];
  Future<void> load() async { items = await AppDb.all(); notifyListeners(); }
  Future<void> add(Expense e) async { await AppDb.insert(e); await load(); }
}
final store = ExpenseStore();
