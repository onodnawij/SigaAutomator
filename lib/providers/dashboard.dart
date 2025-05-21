import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:siga/api/siga_api.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/utils/extensions.dart";
import "package:siga/utils/string_utility.dart";
import "package:flutter/material.dart";
import "package:siga/vars.dart";

final rekapPoktanProvider = ChangeNotifierProvider((ref) => RekapPoktanProgress(ref));
final rekapPoktanProgressLoading = StateProvider((ref) => true);

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
  
  List<Map>? get donePrev {
    return list?.where((elem) => elem["prevProgress"]).toList();
  }

  List<Map>? get notYet {
    return list?.where((elem) => !elem["progress"]).toList();
  }

  List<Map>? get notYetPrev {
    return list?.where((elem) => !elem["prevProgress"]).toList();
  }

  double get percentProgress {
    if (!done.isNullOrEmpty && !list.isNullOrEmpty) {
      return done!.length / list!.length * 100;
    }
    return 0;
  }

  double get percentPrevProgress {
    if (!donePrev.isNullOrEmpty && !list.isNullOrEmpty) {
      return donePrev!.length / list!.length * 100;
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

  RekapPoktanProgress(this.ref) {
    _api = ref.watch(apiProvider);
  }

  operator [](String key) {
    switch (key.toLowerCase()) {
      case "bkb":
        return bkb;
      case "bkl":
        return bkl;
      case "bkr":
        return bkr;
      case "uppka":
        return uppka;
      case "pik-r":
        return pikr;
    }

    return null;
  }

  bool get isProgressLoading => ref.read(rekapPoktanProgressLoading);
  
  Map get progress {
    return {
      "BKB": bkb.percentProgress,
      "BKL": bkl.percentProgress,
      "BKR": bkr.percentProgress,
      "UPPKA": uppka.percentProgress,
      "PIK-R": pikr.percentProgress,
    };
  }

  Map get prevProgress {
    return {
      "BKB": bkb.percentPrevProgress,
      "BKL": bkl.percentPrevProgress,
      "BKR": bkr.percentPrevProgress,
      "UPPKA": uppka.percentPrevProgress,
      "PIK-R": pikr.percentPrevProgress,
    };
  }

  set isProgressLoading(newValue) {
    ref.read(rekapPoktanProgressLoading.notifier).state = newValue;
    notifyListeners();
  }

  void refresh() async {
    isProgressLoading = true;
    
    final result = await Future.wait(List<Future>.generate(poktanList.length, (i) {
      return _getter(poktanList[i]);
    }).toList());
    
    bkb.list = result[0];
    bkl.list = result[1];
    bkr.list = result[2];
    uppka.list = result[3];
    pikr.list = result[4];
    isProgressLoading = false;
  }

  DateTime get prevBulanLapor {
    var now = DateTime.now();
    return now.subtract(Duration(days: now.day));
  }

  Future<List<Map>> _getter(String jenis) async {

    var now = DateTime.now();
    var prev = prevBulanLapor;
    
    List listPoktan = await _api.getPoktan(jenis: jenis);
    listPoktan = listPoktan.where((ele) {
      String lastModified = ele["lastModified"];

      if (lastModified.isEmpty) {
        return false;
      }
      
      return parseAutoDate(lastModified.split(" ")[0])!.compareTo(DateTime(2023)) >= 0;
    }).toList();

    for (var poktan in listPoktan) {
      final kegiatanList = await _api.getPoktanKegiatan(idPoktan: poktan["id"], jenis: jenis, detailed: false, silent: true);
      poktan["kegiatan"] = kegiatanList;
      poktan["progress"] = true;
      poktan["prevProgress"] = true;
      poktan["detailPoktan"] = _api.getDetailPoktan(idPoktan: poktan["id"], jenis: jenis);

      if (kegiatanList.isNotEmpty) {
        var kegiatanBulanNow = [];
        var kegiatanBulanPrev = [];

        for (var keg in kegiatanList) {
          var tanggalKeg = parseAutoDate(keg["tanggalKegiatan"]) ?? DateTime(1997);
          if (tanggalKeg.month == now.month) {
            if (tanggalKeg.year == now.year) {
              kegiatanBulanNow.add(keg);
            }
          } else if (tanggalKeg.month == prev.month) {
            if (tanggalKeg.year == prev.year) {
              kegiatanBulanPrev.add(keg);
            }
          }
        }

        if (kegiatanBulanNow.isEmpty) {
          poktan["progress"] = false;
        }
        if (kegiatanBulanPrev.isEmpty) {
          poktan["prevProgress"] = false;
        }
      } else {
        poktan["progress"] = false;
        poktan["prevProgress"] = false;
      }
    }

    return List<Map>.from(listPoktan);
  }
}