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

  // Dữ liệu mẫu dùng chung cho mobile (seed) và web (in-memory)
  static const _demo = [
    ['Highlands Coffee - Khu V', 122000, 0],
    ['Nhà sách Fahasa Đà Nẵng', 200000, 1],
    ['Căn tin Khu V - Đại học VKU', 40000, 0],
    ['Circle K Nam Kỳ Khởi Nghĩa', 46000, 3],
    ['Cây xăng Petrolimex Hòa Khánh', 70000, 2],
    ['Rạp CGV Vincom Đà Nẵng', 150000, 4],
  ];

  static List<Expense> _demoExpenses() {
    final now = DateTime.now();
    return [
      for (var i = 0; i < _demo.length; i++)
        Expense(
          id: i + 1,
          merchant: _demo[i][0] as String,
          amount: _demo[i][1] as int,
          category: categories[_demo[i][2] as int].name,
          date: now.subtract(Duration(days: i)),
        ),
    ];
  }

  // Chỉ dùng cho web (không có SQLite)
  static final List<Expense> _webItems = kIsWeb ? _demoExpenses() : [];
  static Map<String, Object?>? _webAdvice;

  static Future<Database> get db async => _db ??= await openDatabase(
        p.join(await getDatabasesPath(), 'expense.db'),
        version: 2,
        onCreate: (d, v) async {
          await d.execute(_expensesSql);
          await d.execute(_adviceSql);
          await _seed(d); // chỉ chạy 1 lần, lúc database được tạo
        },
        onUpgrade: (d, oldV, newV) async {
          if (oldV < 2) await d.execute(_adviceSql);
        },
      );

  static Future<void> _seed(Database d) async {
    final batch = d.batch();
    for (final e in _demoExpenses()) {
      batch.insert('expenses', e.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<void> insert(Expense e) async {
    if (kIsWeb) {
      _webItems.add(Expense(
        id: _webItems.length + 1,
        merchant: e.merchant,
        amount: e.amount,
        category: e.category,
        date: e.date,
        imagePath: e.imagePath,
      ));
      return;
    }
    await (await db).insert('expenses', e.toMap());
  }

  static Future<List<Expense>> all() async {
    if (kIsWeb) {
      final list = [..._webItems];
      list.sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : (b.id ?? 0).compareTo(a.id ?? 0);
      });
      return list;
    }
    final rows = await (await db).query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  // Lưu/đọc gợi ý Gemini để xem lại khi offline
  static Future<void> saveAdvice(String text) async {
    final row = {'id': 1, 'text': text, 'updated': DateTime.now().toIso8601String()};
    if (kIsWeb) {
      _webAdvice = row;
      return;
    }
    await (await db).insert('advice', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, Object?>?> loadAdvice() async {
    if (kIsWeb) return _webAdvice;
    final r = await (await db).query('advice', where: 'id = 1');
    return r.isEmpty ? null : r.first;
  }
}

class ExpenseStore extends ChangeNotifier {
  List<Expense> items = [];
  Future<void> load() async {
    items = await AppDb.all();
    notifyListeners();
  }

  Future<void> add(Expense e) async {
    await AppDb.insert(e);
    await load();
  }
}

final store = ExpenseStore();
