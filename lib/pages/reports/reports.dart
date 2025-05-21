import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siga/pages/home.dart' show PoktanProgress;

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  final String title = "Reports";
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700),
        )
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Wrap(
              children: [
                PoktanProgress(prev: false),
                PoktanProgress(prev: true),
              ],
            )
          ],
        )
      )
    );
  }
}