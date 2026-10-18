import 'package:flutter/material.dart';

class Category {
  final String name, short, emoji;
  final Color color;
  const Category(this.name, this.short, this.emoji, this.color);
}

const categories = [
  Category('Ăn uống (F&B)', 'Ăn uống', '🍜', Color(0xFFF97316)),
  Category('Học tập & Giáo trình', 'Học tập', '📚', Color(0xFF3B82F6)),
  Category('Di chuyển & Xăng xe', 'Di chuyển', '🛵', Color(0xFF10B981)),
  Category('Mua sắm & Siêu thị', 'Mua sắm', '🛍️', Color(0xFFEC4899)),
  Category('Giải trí & Hoạt động', 'Giải trí', '🎮', Color(0xFF8B5CF6)),
];
Category categoryOf(String name) =>
    categories.firstWhere((c) => c.name == name, orElse: () => categories.first);

class Expense {
  final int? id;
  final String merchant, category;
  final int amount; // VND, số nguyên
  final DateTime date;
  final String? imagePath;
  const Expense({this.id, required this.merchant, required this.amount, required this.date, required this.category, this.imagePath});

  Map<String, Object?> toMap() => {
        'merchant': merchant, 'amount': amount, 'category': category,
        'date': date.toIso8601String().substring(0, 10), 'image_path': imagePath,
      };
  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?, merchant: (m['merchant'] ?? '') as String, amount: m['amount'] as int,
        category: (m['category'] ?? categories.first.name) as String,
        date: DateTime.parse(m['date'] as String), imagePath: m['image_path'] as String?);
}
