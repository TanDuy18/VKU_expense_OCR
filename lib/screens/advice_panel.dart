import 'package:flutter/material.dart';
import '../advice/local_advisor.dart';
import '../data/db.dart';
import '../theme.dart';
import '../widgets.dart';

/// Gợi ý tiết kiệm tính trực tiếp trên máy: cập nhật ngay khi có giao dịch mới, không cần mạng hay nút bấm.
class AdvicePanel extends StatelessWidget {
  const AdvicePanel({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => Panel(
          title: 'Gợi ý tiết kiệm',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final t in localAdvice(store.items))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('•  '),
                  Expanded(child: Text(t, style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink))),
                ]),
              ),
            Text('Tính trực tiếp trên máy, không cần Internet', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      );
}
