import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnggotaPageBKL extends ConsumerStatefulWidget {
  final dynamic index;
  final String menu;
  final String jenis;
  
  const AnggotaPageBKL({super.key, required this.index, required this.menu, required this.jenis});
  
  @override
  ConsumerState<AnggotaPageBKL> createState() => _AnggotaPageBKLState();
}

class _AnggotaPageBKLState extends ConsumerState<AnggotaPageBKL> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}