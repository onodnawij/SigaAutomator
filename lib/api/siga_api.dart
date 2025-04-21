import "dart:convert";
import "dart:math";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_easyloading/flutter_easyloading.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:siga/api/format.dart";
import "package:siga/api/models/response.dart";
import "package:siga/api/models/user.dart";
import "package:siga/api/urls.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/utils/extensions.dart";
import "package:siga/utils/string_utility.dart";
import "package:siga/vars.dart";

class SigaApi {
  static const POST = 'POST';
  static const GET = 'GET';
  final Ref ref;
  final Dio session = Dio(
    BaseOptions(
      baseUrl: URL.api,
      receiveTimeout: requestTimeOutDuration,
      sendTimeout: requestTimeOutDuration,
    ),
  );

  SigaApi({required this.ref});

  List anggotaBKBValid(Map poktan, String jenis, bool perempuan) {
    List anggota =
        poktan["anggotaKelompok"].where((element) {
          if (jenis.toLowerCase() == 'bkb') {
            var diff =
                DateTime.now()
                    .difference(parseAutoDate(element["tanggalLahirAnak"])!)
                    .inDays ~/
                365;
            return diff < 7;
          } else {
            return true;
          }
        }).toList();

    anggota.shuffle(Random());

    if (perempuan) {
      return anggota
          .where((element) => int.parse(element["nik"][6]) > 3)
          .toList();
    }

    return anggota;
  }

  Future<ApiResponse> upsertPoktan({required Map detailPoktan, required Map upsertData}) async {
    final payload = formatUpsertPoktanBKB.map((k, v) {
      return MapEntry(k, upsertData.containsKey(k) ? upsertData[k] : v);
    });

    String upsertPath = URL.poktanUpsert.replaceAll(
      "{}",
      (poktanList.elementAtOrNull(int.tryParse(detailPoktan["kodePoktan"] ?? "100")! - 1) ?? "unknown").capitalize!,
    );
    
    Map<String, dynamic> headers = {
      "Accept": "application/json, text/plain, */*",
      "Authorization": "Bearer ${ref.read(userProvider).user!.token}",
      "Content-Type": "application/json",
    };

    return await _request(
      upsertPath,
      POST,
      data: payload,
      headers: headers,
    );
  }

  Future<Map> autoAnggotaPoktan({
    required Map itemDetails,
    List? listKeluarga,
    required String jenis,
    List? fixItems,
    int? jumlah,
    int? idRw,
    int maxUsiaIbu = 45,
    int maxUsiaAnak = 6
  }) async {

    //Function upsertTask
    Future<Map> upsertTask(List c) async {
      var format = {};

      switch (jenis.toLowerCase()) {
        case "bkb":
          format = formatUpsertPoktanBKB;
        case "bkl":
          format = formatUpsertPoktanBKL;
        // case "bkr":
        //   format = formatUpserPoktanBKR;
        // case "uppka":
        //   format = formatUpsertPoktanUPPKA;
        // case "pik-r":
        //   format = formatUpsertPoktanPIKR;
      }

      if (format.isEmpty) {
        throw UnimplementedError();
      }
      
      final pengurus = itemDetails["pengurusKelompok"].map((p) {
        return {
          for (var k in format["pengurusKelompok"][0].keys.toList())
            k: k != "nomor" ? p[k] : int.parse(p["nomorUrut"].toString())
        };
      }).toList();

      List anggota = List.from(c);

      if (itemDetails["anggotaKelompok"].length != c.length) {
        anggota = itemDetails["anggotaKelompok"].map((a) {
          return {
            for (var k in format["anggotaKelompok"][0].keys.toList())
            k: k != "nomor" ? a[k] : int.parse(a["nomorUrut"].toString())
          };
        }).toList() + c;
      }
      
      Map payload = formatUpsertPoktanBKB.map((k, v) {
        dynamic val;
        
        if (k == "pengurusKelompok") {
          val = pengurus;
        } else if (k == "anggotaKelompok") {
          val = anggota;
        } else {
          val = itemDetails[k];
        }
        
        return MapEntry(k, val);
      });

      payload.addAll({
        "lastModified": DateTime.now().toUtc().toIso8601String(),
        "lastModifiedBy": ref.read(userProvider).user!.userName,
      });

      print(payload);

      String upsertPath = URL.poktanUpsert.replaceAll(
        "{}",
        jenis.capitalize!,
      );
      
      Map<String, dynamic> headers = {
        "Accept": "application/json, text/plain, */*",
        "Authorization": "Bearer ${ref.read(userProvider).user!.token}",
        "Content-Type": "application/json",
      };

      final upsertResp = await _request(
        upsertPath,
        POST,
        data: payload,
        headers: headers,
      );
      
      if (upsertResp.status == 200) {
        return {"status": 200, "data": c.length};
      } else {
        return upsertResp.toJson();
      }
    }


    if (fixItems != null) {

      return upsertTask(fixItems);
    }

    //If fixItems is null, run these.

    //Assertion
    listKeluarga!;
    jumlah!;

    // handle required "nomor" key in POST data
    int nextNomor() {
      return itemDetails["anggotaKelompok"].length > 0
        ? (int.tryParse(itemDetails["anggotaKelompok"].last["nomorUrut"]) ?? 0) + 1
        : 0;
    }
    
    // handling duplicates
    final anggotaNik = List.generate(itemDetails["anggotaKelompok"].length, (i) {
      return itemDetails["anggotaKelompok"][i]["nik"];
    }).toList();

    if (jenis == "bkb") {
      // final timestamp = DateTime.now().toUtc().toIso8601String();

      // Function populateCalons
      Future<bool> populateCalonsBKB(Map keluarga, List c) async {
        if (c.length >= jumlah) {
          return false;
        }

        List detailKeluarga = [];
        for (var i = 0; i < 5; i++) {
          detailKeluarga = await getChildData(keluarga["noKeluarga"]);

          if (detailKeluarga.isNotEmpty) {
            break;
          }
        }

        if (c.length == jumlah) {
          return false;
        }

        final List sasaran = detailKeluarga
          .where((x) => x["hubunganDenganKk"] == "Anak" && x["usia"] < 6)
          .toList();

        if (sasaran.isEmpty) {
          return false;
        }

        final anak = sasaran.reduce((a, b) => a['usia'] < b['usia'] ? a : b);
        final ibu = detailKeluarga.firstWhereOrNull((ele) => ele["hubunganDenganKk"] == "Istri")
          ?? detailKeluarga[0];

        Map calon = {
          "nik": ibu["nik"],
          "namaAnggota": ibu["nama"],
          "nomorHp": (keluarga["noTelepon"] ?? "").length > 1
            ? keluarga["noTelepon"]
            : "-",
          "nikAnggota": anak["nik"],
          "namaAnak": anak["nama"],
          "pbLahirAnak": double.parse((47 + Random().nextDouble() * 4).toStringAsFixed(1)),
          "bbLahirAnak": ((270 + Random().nextInt(91)) * 10).toString(),
          "kki": ibu["noKeluarga"],
          "noKeluarga": ibu["noKeluarga"],
          "tanggalLahirAnak": DateFormat("dd-MM-yyyy").format(parseAutoDate(anak["tanggalLahir"])!),
          "BKBID": itemDetails["id"],
          "statusAnggota": "1",
          "flag": "Upsert"
        };

        if (c.length >= jumlah) {
          return false;
        }

        c.add(calon);
        return true;
      } // Function populateCalons

      // Main code is here
      List calons = [];
      
      final result = await Future.wait(listKeluarga.map<Future<bool>>((keluarga) {
        if (!anggotaNik.contains(keluarga["nik"])) {
          return populateCalonsBKB(keluarga, calons);
        } else {
          return Future.value(false);
        }
      }).toList());

      if (!result.every((elem) => elem)) {
        print("Auto Anggota: some item skipped");
      }

      for (var i = 0; i < calons.length; i++) {
        calons[i].addAll({
          "nomor": nextNomor() + i,
          "nomorUrut": (nextNomor() + i).toString(),
        });
      }
      
      return upsertTask(calons);
    } else if (jenis == "bkl") {
      // Function populate calons
      Future<bool> populateCalonsBKL(Map keluarga, List c) async {
        if (c.length == jumlah) {
          return false;
        }
        
        final detailKeluarga = await getChildData(keluarga["noKeluarga"]);

        if (c.length == jumlah) {
          return false;
        }

        final sasaran = detailKeluarga.where((x) => (x["usia"] >= 55 && x["usia"] < 70) || x["hubunganDenganKK"] == "Istri").toList();
        if (sasaran.isEmpty) {
          return false;
        }

        sasaran.shuffle();

        final isLansia = sasaran[0]["usia"] >=  60;

        Map calon = {
          "nik": sasaran[0]["nik"],
          "namaAnggota": sasaran[0]["nama"],
          "nomorHp": keluarga["noTelepon"],
          "statusLansia": isLansia ? "1" : "2",
          "tingkatKemandirian": "1",
          "kki": keluarga["noKeluarga"],
          "noKeluarga": keluarga["noKeluarga"],
          "statusLansia_tbl": isLansia ? "Ya" : "Tidak",
          "tingkatKemandirian_tbl": "Mandiri",
          "flag": "Upsert"
        };

        if (c.length >= jumlah) {
          return false;
        }

        c.add(calon);
        return true;
      }

      // main code is here
      List calons = [];
      final result = await Future.wait(listKeluarga.map<Future<bool>>((keluarga) async {
        if (!anggotaNik.contains(keluarga["nik"])) {
          return populateCalonsBKL(keluarga, calons);
        } else {
          return Future.value(false);
        }
      }).toList());
      
      if (!result.every((elem) => elem)) {
        print("Auto Anggota: some item skipped");
      }
      for (var i = 0; i < calons.length; i++) {
        calons[i].addAll({
          "nomor": nextNomor() + i,
          "nomorUrut": (nextNomor() + i).toString(),
          "nomorBKL": (nextNomor() + i).toString().padLeft(3, '0'),
        });
      }
      
      return upsertTask(calons);
    }
    
    return {"status": 404, "data": "not supported"};
  }
  

  Future<bool> autoKegiatan({
    required Map item,
    required Map data,
    required String jenis,
    bool? editItem,
  }) async {
    final user = ref.read(userProvider).user!;
    var parsedTanggal = parseAutoDate(data["tanggal"])!;
    var mengetahuiTempat = item["mengetahuiTempat"];

    var namaCalon = [];
    var calon = [];

    final Map detailPoktan = await getDetailPoktan(
      idPoktan: item["id"],
      jenis: jenis,
    );
    var anggotaKelompok = anggotaBKBValid(detailPoktan, jenis, data["perempuan"]);
    if (jenis.toLowerCase() == "bkb") {
      await Future.wait(
        List.generate(anggotaKelompok.length, (index) {
          return _makePayloadBkb(
            data["tanggal"],
            calon,
            namaCalon,
            anggotaKelompok[index],
            item,
          );
        }),
      );
    } else if (jenis.toLowerCase() == "bkl") {
      await Future.wait(
        List.generate(anggotaKelompok.length, (index) {
          return _makePayloadBkl(
            data["tanggal"],
            calon,
            namaCalon,
            anggotaKelompok[index],
            item,
          );
        }),
      );
    } else {
      return false;
    }

    if (calon.length > data["maxPeserta"]) {
      calon = calon.sublist(0, data["maxPeserta"]);
    }

    Future<Map> sendPayload(c) async {
      Map<String, dynamic> payload = {
        "kegiatan${jenis.capitalize}": {
          "kegiatan": {
            "id": item["id"].toString(),
            "tahun": parsedTanggal.year.toString(),
            "bulan": parsedTanggal.month.toString(),
            "kelompokUmur0_2": "0",
            "kelompokUmur1_2": "0",
            "kelompokUmur2_3": "0",
            "kelompokUmur3_4": "0",
            "kelompokUmur4_5": "0",
            "kelompokUmur5_6": "0",
            "diskusiAda": "0",
            "tanggalKegiatan": data["tanggal"],
            "tanggalKegiatanBaru": data["tanggal"],
            "metodeOffline": "1",
            "metodeOnline": "0",
            "mengetahuiTempat": mengetahuiTempat,
            "mengetahuiTanggal": data["tanggal"],
            "mengetahuiKetuaNama": item["mengetahuiKetuaNama"],
            "mengetahuiPembinaNama": item["mengetahuiPembinaNama"],
            "loginName": user.userName,
            "status": "1",
            "statusDate": DateFormat("dd-MM-yyyy").format(DateTime.now()),
          },
          "pesertaKegiatan": c,
        },
      };

      Map<String, dynamic> materi = data["materi"]
          .sublist(0, data["materi"].length - 1)
          .asMap()
          .map<String, dynamic>(
            (index, value) => MapEntry(
              "materiPenyuluhan${(index + 1).toString().padLeft(2, '0')}",
              value ? "1" : "0",
            ),
          );

      materi.addAll({
        "materiPenyuluhanLainnya": data["materi"].last ? "1" : "0",
        "materiPenyuluhanLainnyaDeskripsi":
            data["materiLainnya"].isEmpty
                ? null
                : data["materiLainnya"].isEmpty,
      });

      Map<String, dynamic> narasumber = data["narasumber"]
          .sublist(0, data["narasumber"].length - 1)
          .asMap()
          .map<String, dynamic>(
            (index, value) => MapEntry(
              "penyajiNaraSumber${narsumPoktan.keys.toList()[index]}",
              value ? "1" : "0",
            ),
          );

      narasumber.addAll({
        "penyajiNaraSumberLainnya": data["narasumber"].last ? "1" : "0",
        "penyajiNaraSumberLainnyaDeskripsi":
            data["narasumberLainnya"].isEmpty
                ? null
                : data["narasumberLainnya"],
      });

      payload["kegiatan${jenis.capitalize}"]["kegiatan"].addAll(materi);
      payload["kegiatan${jenis.capitalize}"]["kegiatan"].addAll(narasumber);

      Map<String, dynamic> headers = {
        "Accept": "application/json, text/plain, */*",
        "Authorization": "Bearer ${user.token}",
        "Content-Type": "application/json",
      };

      String upsertPath = URL.poktanUpsertKegiatan.replaceAll(
        "{jenis}",
        jenis.toLowerCase(),
      );

      final upsertResp = await _request(
        upsertPath,
        POST,
        data: payload,
        headers: headers,
      );
      return upsertResp.toJson();
    }

    if (editItem != null && editItem) {
      String detailKegiatanPath = URL.poktanDetailKegiatan
          .replaceAll("{id}", item["id"])
          .replaceAll("{tanggal}", data["tanggal"])
          .replaceAll("{jenis}", jenis.toLowerCase());

      final orig = await _request(detailKegiatanPath, GET);
      List origPeserta =
          json.decode(orig.data)["kegiatan${jenis.capitalize}"]["pesertaKegiatan"];

      if (origPeserta.isNotEmpty) {
        await sendPayload(
          List.generate(origPeserta.length, (i) {
            Map thisPeserta = origPeserta[i];
            thisPeserta["flag"] = "Delete";
            return thisPeserta;
          }),
        );
      }
    }

    final Map retValue = await sendPayload(calon);
    return retValue["status"] == 200;
  }

  Future<int> _makePayloadBkl(
    String tanggal,
    List calon,
    List namaCalon,
    Map anggota,
    Map item,
  ) async {
    int status = 0;

    try {
      var parsedTanggal = parseAutoDate(tanggal)!;

      String path = URL.parentRekapPK
          .replaceAll("{bulan}", parsedTanggal.month.toString())
          .replaceAll("{tahun}", parsedTanggal.year.toString())
          .replaceAll("{nik}", anggota["nik"])
          .replaceAll("{nama}", anggota["nama"])
          .replaceAll("{provinsi}", item["provinsiId"].toString())
          .replaceAll("{kabupaten}", item["kabupatenId"].toString())
          .replaceAll("{kecamatan}", item["kecamatanId"].toString())
          .replaceAll("{kelurahan}", item["kelurahanId"].toString());

      final parentResp = await _request(path, GET);
      List? dataParent = json.decode(parentResp.data)["data"];

      if (dataParent!.isNotEmpty) {
        Map parent = dataParent[0];
        String statusPus = parent["statusPus"] ? "1" : "2";
        String statusLansia = parent["usia"] >= 60 ? "1" : "2";
        String statusBerKb = parent["metodeKontrasepsi"] != null ? "1" : "2";

        var nomor = calon.length + 1;

        Map peserta = {
          "id": item["id"],
          "kki": anggota["kki"],
          "nomorBKL": anggota["nomorBKL"],
          "nama": anggota["namaAnggota"],
          "nik": anggota["nik"],
          "jumlahLansiaMandiri": "0",
          "jumlahLansiaPJP": "0",
          "statusBerKB": statusBerKb,
          "statusPUS": statusPus,
          "tanggalKegiatan": tanggal,
          "statusLansia": statusLansia,
          "statusBerKb_tbl": statusBerKb == "1" ? "Ya" : "Tidak",
          "statusPus_tbl": statusPus == "1" ? "Ya" : "Tidak",
          "statusLansia_tbl": statusLansia == "1" ? "Ya" : "Tidak",
          "flag": "Upsert",
          "nomorUrut": nomor,
          "tanggalKegiatanBaru": tanggal,
        };

        if (!namaCalon.contains(anggota["namaAnggota"])) {
          calon.add(peserta);
          namaCalon.add(anggota["namaAnggota"]);
        }
      }
    } catch (e, s) {
      print(e);
      print(s);
    }

    return status;
  }

  Future<List> getChildData(String kki) async {
    DateTime tanggal = DateTime.now();

    var headers = {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'DNT': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Upgrade-Insecure-Requests': '1',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36',
      'sec-ch-ua': '"Google Chrome";v="135", "Not-A.Brand";v="8", "Chromium";v="135"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"'
    };

    var childPath = URL.childRekapPK
        .replaceAll("{bulan}", tanggal.month.toString())
        .replaceAll("{tahun}", tanggal.year.toString())
        .replaceAll("{kki}", kki.replaceAll(" ", "%20"));
     
    final resp = await _request(childPath, GET, headers: headers);
    final ret =  json.decode(resp.data.isEmpty ? "[]" : resp.data);
    if (ret.isEmpty) {
      print("WARNNG: empty return!\nurl: $childPath");
    }

    return ret;
  }

  Future<List> getParentData({
    required String idKelurahan,
    String? idRw,
    String? idRt,
    Map<String, dynamic>? filters,
  }) async {
    final user = ref.read(userProvider).user!;
    
    var tanggal = DateTime.now();

    Map<String, dynamic> param = {
      "bulan": tanggal.month.toString(),
      "tahun": tanggal.year.toString(),
      "page": "1",
      "recordPerPage": "10",
      "idProvinsi": user.wilProvinsi!.idProvinsi.toString(),
      "idKabupaten": user.wilKabupaten!.idKabupaten.toString(),
      "idKecamatan": user.wilKecamatan.idKecamatan.toString(),
      "idKelurahan": idKelurahan,
    };

    if (idRw != null) {
      param["idRw"] = idRw;
    } else {
      final kelurahan = user.wilKecamatan.wilKelurahan.firstWhereOrNull((elem) => elem.idKelurahan!.toString() == idKelurahan);
      final result = await Future.wait(List<Future<List>>.generate(kelurahan!.wilRw.length, (i) {
        final idRw = kelurahan.wilRw[i].idRw.toString();
        return getParentData(idKelurahan: idKelurahan, idRw: idRw, idRt: idRt, filters: filters);
      }));

      return result.expand((x) => x).toList();
    }

    if (idRt != null && param.containsKey("idRw")) {
      param["idRt"] = idRt;
    }

    if (filters != null) {
      param.addAll(filters);
    }

    Future<List> getParentDataTask(url) async {
      final resp = await _request(url, GET);
      return json.decode(resp.data)["data"];
    }

    final encodedParams = param.entries
    .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
    .join('&');

    final path = "${URL.parentRekapPK}?$encodedParams";
    int total = 0;

    for (int i = 0; i < 5; i++) {
      final resp = await _request(path, GET);
      if (json.decode(resp.data).containsKey("totalRecord")) {
        total = json.decode(resp.data)["totalRecord"];
        break;
      }
    }

    List result = await Future.wait(List<Future>.generate((total / 10).ceil(), (i) {
      param["page"] = (i+1).toString();
      var pagedEncodedParam = param.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
      var pagedPath = "${URL.parentRekapPK}?$pagedEncodedParam";
      return getParentDataTask(pagedPath);
    }));
    
    var ret = result.expand((element) => element).toList();
    return ret;
  }

  Future<int> _makePayloadBkb(
    String tanggal,
    List calon,
    List namaCalon,
    Map anggota,
    Map item,
  ) async {
    int status = 0;

    try {
      var parsedTanggal = parseAutoDate(tanggal)!;
      
      var filters = {
        "nama": anggota["namaAnggota"],
        "nik": anggota["nik"],
        "bulan": parsedTanggal.month.toString(),
        "tahun": parsedTanggal.year.toString(),
      };

      final dataParent = await getParentData(idKelurahan: item["kelurahanId"], filters: filters);

      if (dataParent.isNotEmpty) {
        Map parent = dataParent[0];

        String statusPus = parent["statusPus"] ? "1" : "2";
        String statusHamil = parent["statusHamil"] ? "1" : "2";
        String statusBerKb = parent["metodeKontrasepsi"] != null ? "1" : "2";

        List childData = await getChildData(anggota["kki"]);

        Map child =
            childData.where((child) => child["usia"] <= 6).toList().last;
        var tanggalLahirAnak = DateFormat(
          "dd-MM-yyyy",
        ).format(parseAutoDate(child["tanggalLahir"])!);

        var nomor = calon.length + 1;

        Map peserta = {
          "id": null,
          "nomorUrut": nomor,
          // "idAnggota": nomor,
          "nik": anggota["nik"],
          "kki": anggota["kki"],
          "keanggotaan": "1",
          "keanggotaan_tbl": "Ya",
          "nama": anggota["namaAnggota"],
          "penggunaanKKA": "1",
          "kka": "Ya",
          "penggunaanKMS": "1",
          "kms": "Ya",
          "perkembanganAnak": "1",
          "perkembanganAnak_tbl": "1. Sesuai",
          "statusPUS": statusPus,
          "statusPus_tbl": statusPus == "1" ? "Ya" : "Tidak",
          "statusHamil": statusHamil,
          "statusHamil_tbl": statusHamil == "1" ? "Ya" : "Tidak",
          "statusBerKB": statusBerKb,
          "statusKB_tbl": statusBerKb == "1" ? "Ya" : "Tidak",
          "tanggalKegiatan": tanggal,
          "tanggalKegiatanBaru": tanggal,
          "namaAnak": child["nama"],
          "tanggalLahirAnak": tanggalLahirAnak,
          "flag": "Upsert",
        };

        if (!namaCalon.contains(anggota["namaAnggota"])) {
          calon.add(peserta);
          namaCalon.add(anggota["namaAnggota"]);
        }
      }
    } catch (e, s) {
      print(e);
      print(s);
      status = 1;
    }

    return status;
  }

  Future<List> getPoktanKegiatan({
    required String idPoktan,
    required String jenis,
    bool detailed = true,
    bool silent = false,
  }) async {
    final user = ref.read(userProvider).user!;
    
    Future<Map> fetchDetail(String tanggal) async {
      Map details = await getDetailPoktanKegiatan(
        idPoktan: idPoktan,
        tanggalKegiatan: tanggal,
        jenis: jenis,
      );
      Map keg = details["kegiatan${jenis.capitalize}"]["kegiatan"];
      List pesertaKegiatan =
          details["kegiatan${jenis.capitalize}"]["pesertaKegiatan"];
      keg["pesertaKegiatan"] = pesertaKegiatan;
      return keg;
    }

    var path = URL.poktanListKegiatan
        .replaceAll("{id}", idPoktan.toString())
        .replaceAll("{jenis}", jenis);

    await user.initDone;

    final ret = await withRetry(() async {
      final resp = await _request(path, GET);
      List keg = json.decode(resp.data)["kegiatan${jenis.capitalize}"];
      return keg;
    }, silent: silent,
    );

    if (ret == null && !silent) {
      print("$idPoktan $jenis");
    }

    List data = ret ?? [];

    data.sort((a, b) => parseAutoDate(b["tanggalKegiatan"])!.compareTo(parseAutoDate(a["tanggalKegiatan"])!));

    if (!detailed) {
      return data;
    }
    

    for (int i = 0; i < data.length; i++) {
      data[i] = await fetchDetail(data[i]["tanggalKegiatan"]);
    }

    return data;
  }

  Future<Map> getDetailPoktan({
    required String idPoktan,
    required String jenis,
  }) async {
    var path = URL.poktanDetail
        .replaceAll("{id}", idPoktan)
        .replaceAll("{jenis}", jenis);

    final resp = await _request(path, GET);
    return json.decode(resp.data)["poktan${jenis.capitalize}"];
  }

  Future<List> getPoktan({int? idKelurahan, required String jenis}) async {
    final user = ref.read(userProvider).user!;
    
    var param = {
      "provinsiId": "15",
      "kabupatenId": "245",
      "kecamatanId": "${user.wilKecamatan.idKecamatan}",
      "kelurahanId": "${idKelurahan ?? 0}",
      "rwId": "0",
      "rtId": "0",
    };

    var path = URL.poktanList
        .replaceAll('{param}', Uri.decodeComponent(json.encode(param)))
        .replaceAll('{jenis}', jenis.toLowerCase());

    await user.initDone;

    for (int i = 0; i < 5; i++) {
      final resp = await _request(path, GET);
      if (resp.data.isNotEmpty) {
        return json.decode(resp.data);
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> getDetailPoktanKegiatan({
    required String idPoktan,
    required String tanggalKegiatan,
    required String jenis,
  }) async {
    var path = URL.poktanDetailKegiatan
        .replaceAll('{id}', idPoktan)
        .replaceAll("{tanggal}", tanggalKegiatan)
        .replaceAll("{jenis}", jenis);

    final resp = await _request(path, GET);

    return json.decode(resp.data) as Map<String, dynamic>;
  }

  Future<bool> getUser({
    required String username,
    required String password,
    required BuildContext context,
    Map<String, dynamic>? userData,
  }) async {

    if (userData != null) {
      showLoading();
      userData['api'] = this;
      ref.read(userProvider).update(User.fromJson(userData));
      await ref.read(userProvider).user!.initDone;
      await Future.delayed(Duration(seconds: 1));
      dismiss();
      showSuccess("Welcome Back!");
      return true;
    }
    
    showLoading();
    Map data = {"username": username, "password": password, "idAplikasi": 2};
    final resp = await _request(URL.auth, POST, data: data);
    dismiss();
    if (resp.status == 200) {
      Map<String, dynamic> user =
          json.decode(resp.data)["authorities"][0]["attributes"]["user"];

      if (user['namaLevelWilayah'] != 'Kecamatan') {
        showError('kamu tuh bukan operator Kecamatan!');
        return false;
      }

      showLoading();

      user['token'] = json.decode(resp.data)['accessToken'];
      user['api'] = this;
      ref.read(userProvider).update(User.fromJson(user));
      while (true) {
        final result = await ref.read(userProvider).user!.initDone;

        if (result) {
          break;
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

      dismiss();

      showSuccess('Logged In!');
    } else if (resp.status == 401) {
      showError('Username atau password salah!');
    } else if (resp.status == 500) {
      showError('Username dan password kosong?');
    }

    return resp.status == 200;
  }

  Future<List<WilKelurahan>> getKelurahan(int idKecamatan) async {
    final ret = await withRetry(() async {
      final resp = await _request("${URL.wilayahKelurahan}$idKecamatan", GET);
      if (resp.data.isNotEmpty) {
        List kelurahanList = json.decode(resp.data);
        return List.generate(kelurahanList.length, (i) {
          var kelurahan = kelurahanList[i];
          kelurahan['api'] = this;
          return WilKelurahan.fromJson(kelurahan);
        });
      }
      return null;
    });
    return ret ?? [];
  }

  Future<List<WilRw>> getRw(int idKelurahan) async {
    final ret = await withRetry(() async {
        final resp = await _request("${URL.wilayahRw}$idKelurahan", GET);
        List rwList = json.decode(resp.data);
        return List.generate(rwList.length, (i) {
          var rw = rwList[i];
          rw['api'] = this;
          return WilRw.fromJson(rw);
        });
    });

    return ret ?? [];
  }

  Future<List<WilRt>> getRt(int idRw) async {
     final ret = await withRetry(() async {
        final resp = await _request("${URL.wilayahRt}$idRw", GET);
        List rtList = json.decode(resp.data);
        return List.generate(rtList.length, (i) => WilRt.fromJson(rtList[i])); 
     });

    return ret ?? [];
  }

  Future<T?> withRetry<T>(Future<T> Function() fun, {bool silent = false}) async {
    dynamic error;
    for (int i = 0; i < 5; i++) {
      try {
        var ret = await fun();
        if (ret != null) {
          return ret;
        }
      } catch (e) {
        error = e;
      }
    }
    if (!silent) {
      print(error);
      showError("SIGA lagi ucak");
    }
    return null;
  }

  Future<ApiResponse> _request(
    String path,
    String method, {
    Map? data,
    Map<String, dynamic>? headers,
    bool? debug,
  }) async {
    session.options.method = method;
    session.options.responseType = ResponseType.plain;
    int respStatus = 200;
    String respData = "";

    if (headers != null) {
      session.options.headers = headers;
    }

    try {
      final resp = await session.request(path, data: data);

      if (debug ?? false) {
        print(resp.toString());
      }
      
      respData = resp.toString();
      
    } on DioException catch (e, s) {
      if (e.response != null) {
        try {
          var errData = json.decode(e.response!.data);

          print("errData: $errData");
          
          if (errData.containsKey("status")) {
            respStatus = int.parse(errData["status"].toString());
            respData = errData["message"] ?? "";
          } else {
            respStatus = e.response!.statusCode!;
            respData = e.response!.data;
          }
          
        } on FormatException {
          respStatus = e.response!.statusCode!;
          respData = e.response!.statusMessage!;
        }

      } else {
        respData = e.message ?? "";
        respStatus = 0;

        switch (e.type) {
          case DioExceptionType.badCertificate:
            respStatus = 495;
          case DioExceptionType.receiveTimeout:
            respStatus = 504;
          case DioExceptionType.sendTimeout:
            respStatus = 408;
          case DioExceptionType.connectionTimeout:
            respStatus = 408;
          case DioExceptionType.connectionError:
            respStatus = 408;
          case DioExceptionType.badResponse:
            respStatus = 400;
          case DioExceptionType.cancel:
            respStatus = 444;
          case DioExceptionType.unknown:
            print(e.requestOptions.data);
            respStatus = 0;
        }
        var errMessage = apiStatus[respStatus] ?? "Gatau Kenapa";
        showError(errMessage);
        print("$errMessage\ncode: $respStatus\nmessage: $respData");
        print("Error: $e");
        print("stack: $s");
      }
    }
    return ApiResponse(status: respStatus, data: respData);
  }

  void showLoading({String? message}) {
    EasyLoading.instance.backgroundColor = Color.fromARGB(90, 2, 56, 125);
    EasyLoading.show(status: message);
  }

  void dismiss() {
    EasyLoading.dismiss();
  }

  void showInfo(String message) {
    EasyLoading.instance.backgroundColor = Color.fromARGB(172, 2, 56, 125);
    EasyLoading.instance.textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white,
    );
    EasyLoading.showInfo(message, duration: Duration(seconds: 3));
  }

  void showSuccess(String message) {
    EasyLoading.instance.backgroundColor = Color.fromARGB(221, 122, 151, 205);
    EasyLoading.instance.successWidget = Icon(
      Icons.check_circle,
      size: 48,
      color: Colors.white,
    );
    EasyLoading.instance.textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white,
    );
    EasyLoading.showSuccess(message, duration: Duration(seconds: 3));
  }

  void showError(String message, {IconData? icon}) {
    EasyLoading.instance.backgroundColor = Colors.red.shade400.withAlpha(221);
    EasyLoading.instance.errorWidget = Text(
      ":(",
      style: TextStyle(
        fontSize: 28,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    EasyLoading.showError(message, duration: Duration(seconds: 4));
  }

  void showProgress(double progress, String message) {
    EasyLoading.instance.backgroundColor = Color.fromARGB(221, 122, 151, 205);
    EasyLoading.instance.textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white,
    );
    EasyLoading.instance.progressColor = Colors.white;
    EasyLoading.showProgress(progress, status: message);
  }
}
