import 'package:flutter/material.dart';
import '../data/db.dart';
import '../models/expense.dart';
import '../widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _q = '';
  String? _cat; // null = Tất cả
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = store.items.where((e) =>
              (_cat == null || e.category == _cat) && e.merchant.toLowerCase().contains(_q.toLowerCase())).toList();
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(hintText: 'Tìm kiếm cửa hàng, ghi chú…', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
            SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              for (final c in [null, ...categories.map((c) => c.name)])
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(
                  label: Text(c ?? 'Tất cả'), selected: _cat == c, onSelected: (_) => setState(() => _cat = c)))])),
            Expanded(child: list.isEmpty
                ? const Center(child: Text('Không có giao dịch phù hợp'))
                : ListView(padding: const EdgeInsets.all(16), children: [for (final e in list) TxTile(e)])),
          ]);
        },
      );
}
