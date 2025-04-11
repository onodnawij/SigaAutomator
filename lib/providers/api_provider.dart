import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, StateProvider;
import 'package:siga/api/models/user.dart';
import 'package:siga/api/siga_api.dart' show SigaApi;

final isOutdatedProvider = StateProvider<bool?>((ref) => null);
final downloadUrlProvider = StateProvider<String>((ref) => "");
final apiProvider = Provider((ref) => SigaApi(ref: ref));
final userProvider = Provider((ref) => UserProvider());

class UserProvider {
  User? _user;
  User? get user => _user; 
  void update(User? user) {
    _user = user;
  }
}