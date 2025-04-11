import 'package:flutter/material.dart' show Container, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listingCacheProvider = StateProvider<Map<String, List>>((ref) => {});
final listingKeyProvider = StateProvider<String>((ref) => "");
final lastDataLengthProvider = StateProvider<int>((ref) => 3);
final listingContentProvider = StateProvider((ref) => _ContentProvider());

class _ContentProvider {
  Widget content = Container();
  String? errorText;
  Map filter = {};
}