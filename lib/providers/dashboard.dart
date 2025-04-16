import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:siga/api/siga_api.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/utils/extensions.dart";
import "package:siga/utils/string_utility.dart";
import "package:flutter/material.dart";
import "package:siga/vars.dart";

final rekapPoktanProvider = ChangeNotifierProvider((ref) => RekapPoktanProgress(ref));
final rekapPoktanLoadingProvider = StateProvider((ref) => false);

class Progress {
  final List? done;
  final List? notYet;
  final double? percent;

  const Progress({required this.done, required this.notYet, required this.percent});
}

class PoktanProgress {
  List<Map>? list;

  List<Map>? get done {
    return list?.where((elem) => elem["progress"]).toList();
  }

  List<Map>? get notYet {
    return list?.where((elem) => !elem["progress"]).toList();
  }

  double get percent {
    if (!done.isNullOrEmpty && !list.isNullOrEmpty) {
      return done!.length / list!.length * 100;
    }
    return 0;
  }
}

class RekapPoktanProgress extends ChangeNotifier{
  PoktanProgress bkb = PoktanProgress();
  PoktanProgress bkl = PoktanProgress();
  PoktanProgress bkr = PoktanProgress();
  PoktanProgress uppka = PoktanProgress();
  PoktanProgress pikr = PoktanProgress();
  late SigaApi _api;
  final Ref ref;
  bool _isLoading = false;

  RekapPoktanProgress(this.ref) {
    _api = ref.watch(apiProvider);
  }

  bool get isLoading => _isLoading;
  Map get progress {
    return {
      "BKB": bkb.percent,
      "BKL": bkl.percent,
      "BKR": bkr.percent,
      "UPPKA": uppka.percent,
      "PIK-R": pikr.percent,
    };
  }

  set isLoading(newValue) {
    _isLoading = newValue;
    notifyListeners();
  }

  void refresh() async {
    isLoading = true;    
    
    final result = await Future.wait(List<Future>.generate(poktanList.length, (i) {
      return _getter(poktanList[i]);
    }).toList());
    
    bkb.list = result[0];
    bkl.list = result[1];
    bkr.list = result[2];
    uppka.list = result[3];
    pikr.list = result[4];
    isLoading = false;
  }

  Future<List<Map>> _getter(String jenis) async {
    final now = DateTime.now();
    final poktanList = await _api.getPoktan(jenis: jenis);

    for (var poktan in poktanList) {
      final kegiatanList = await _api.getPoktanKegiatan(idPoktan: poktan["id"], jenis: jenis, detailed: false, silent: true);
      poktan["progress"] = true;

      if (kegiatanList.isNotEmpty) {
        final latest = parseAutoDate(kegiatanList[0]["tanggalKegiatan"]);
        if ((latest?.month ?? 0) < now.month) {
          poktan["progress"] = false;
        } 
      }
    }

    return List<Map>.from(poktanList);
  }
}