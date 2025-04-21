import 'package:flutter/material.dart' show Container, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final listingCacheProvider = StateProvider<Map<String, List>>((ref) => {});
final listingKeyProvider = StateProvider<String>((ref) => "");
final lastDataLengthProvider = StateProvider<int>((ref) => 3);
final listingContentProvider = StateProvider((ref) => _ContentProvider());
final listingIndexProvider = StateProvider<int>((ref) => 0);

Map currentListingItem(Ref ref) {
  return ref.read(listingCacheProvider)[ref.read(listingKeyProvider)]![ref.read(listingIndexProvider)];
}

class _ContentProvider {
  Widget content = Container();
  String? errorText;
  Map filter = {};
}