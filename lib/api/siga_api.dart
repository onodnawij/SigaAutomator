import "dart:convert";
import "dart:math";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_easyloading/flutter_easyloading.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:siga/api/models/user.dart";
import "package:siga/api/urls.dart";
import "package:siga/providers/api_provider.dart";
import "package:siga/utils/extensions.dart";
import "package:siga/utils/string_utility.dart";
import "package:siga/vars.dart";

class SigaApi {
  static const POST = 'POST';
  static const GET = 'GET';
  String jenisPoktan = '';
  final Ref ref;
  final Dio session = Dio(
    BaseOptions(
      baseUrl: URL.api,
      receiveTimeout: requestTimeOutDuration,
      sendTimeout: requestTimeOutDuration,
    ),
  );

  SigaApi({required this.ref});

  List anggotaValid(Map poktan, String jenis, bool perempuan) {
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
    var anggotaKelompok = anggotaValid(detailPoktan, jenis, data["perempuan"]);
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
      return upsertResp;
    }

    if (editItem != null && editItem) {
      String detailKegiatanPath = URL.poktanDetailKegiatan
          .replaceAll("{id}", item["id"])
          .replaceAll("{tanggal}", data["tanggal"])
          .replaceAll("{jenis}", jenis.toLowerCase());

      final orig = await _request(detailKegiatanPath, GET);
      List origPeserta =
          orig["data"]["kegiatan${jenis.capitalize}"]["pesertaKegiatan"];

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
      List? dataParent = parentResp["data"]["data"];

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

    var childPath = URL.childRekapPK
        .replaceAll("{bulan}", tanggal.month.toString())
        .replaceAll("{tahun}", tanggal.year.toString())
        .replaceAll("{kki}", kki.replaceAll(" ", "%20"));

    final resp = await _request(childPath, GET);
    return resp["data"];
  }

  Future<List> getParentData({
    String? nama,
    required String nik,
    required String idKelurahan,
  }) async {
    final user = ref.read(userProvider).user!;
    
    var tanggal = DateTime.now();

    String path = URL.parentRekapPK
        .replaceAll("{bulan}", tanggal.month.toString())
        .replaceAll("{tahun}", tanggal.year.toString())
        .replaceAll("{nik}", nik)
        .replaceAll(
          "{provinsi}",
          user.wilProvinsi!.idProvinsi.toString(),
        )
        .replaceAll(
          "{kabupaten}",
          user.wilKabupaten!.idKabupaten.toString(),
        )
        .replaceAll(
          "{kecamatan}",
          user.wilKecamatan.idKecamatan.toString(),
        )
        .replaceAll("{kelurahan}", idKelurahan);

    if (nama != null) {
      path = path.replaceAll("{nama}", nama);
    } else {
      path = path.replaceAll("&nama={nama}", "");
    }

    final resp = await _request(path, GET);

    return resp["data"]["data"];
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

      String path = URL.parentRekapPK
          .replaceAll("{bulan}", parsedTanggal.month.toString())
          .replaceAll("{tahun}", parsedTanggal.year.toString())
          .replaceAll("{nik}", anggota["nik"])
          .replaceAll("{nama}", anggota["namaAnggota"])
          .replaceAll("{provinsi}", item["provinsiId"].toString())
          .replaceAll("{kabupaten}", item["kabupatenId"].toString())
          .replaceAll("{kecamatan}", item["kecamatanId"].toString())
          .replaceAll("{kelurahan}", item["kelurahanId"].toString());

      final parentResp = await _request(path, GET);
      List? dataParent = parentResp["data"]["data"];

      if (dataParent!.isNotEmpty) {
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
    final resp = await _request(path, GET);
    List data = resp["data"]["kegiatan${jenis.capitalize}"];

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
    return resp["data"]["poktan${jenis.capitalize}"];
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
    final resp = await _request(path, GET);
    List data = resp["data"];
    return data;
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

    return resp["data"];
  }

  Future<bool> getUser({
    required String username,
    required String password,
    required BuildContext context,
    Map<String, dynamic>? userData,
  }) async {

    if (userData != null) {
      showLoading(context: context);
      userData['api'] = this;
      ref.read(userProvider).update(User.fromJson(userData));
      await ref.read(userProvider).user!.initDone;
      await Future.delayed(Duration(seconds: 1));
      dismiss();
      showSuccess("Welcome Back!");
      return true;
    }
    
    showLoading(context: context);
    Map data = {"username": username, "password": password, "idAplikasi": 2};
    final Map resp = await _request(URL.auth, POST, data: data);
    dismiss();
    if (resp['status'] == 200) {
      Map<String, dynamic> user =
          resp['data']["authorities"][0]["attributes"]["user"];

      if (user['namaLevelWilayah'] != 'Kecamatan') {
        showError('kamu tuh bukan operator Kecamatan!');
        return false;
      }

      showLoading(context: context);

      user['token'] = resp['data']['accessToken'];
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
    } else if (resp['status'] == 401) {
      showError('Username atau password salah!');
    } else if (resp['status'] == 500) {
      showError('Username dan password kosong?');
    }

    return resp['status'] == 200;
  }

  Future<List<WilKelurahan>> getKelurahan(int idKecamatan) async {
    final resp = await _request("${URL.wilayahKelurahan}$idKecamatan", GET);
    List kelurahanList = resp['data'];
    return List.generate(kelurahanList.length, (i) {
      var kelurahan = kelurahanList[i];
      kelurahan['api'] = this;
      return WilKelurahan.fromJson(kelurahan);
    });
  }

  Future<List<WilRw>> getRw(int idKelurahan) async {
    final resp = await _request("${URL.wilayahRw}$idKelurahan", GET);
    List rwList = resp["data"];
    return List.generate(rwList.length, (i) {
      var rw = rwList[i];
      rw['api'] = this;
      return WilRw.fromJson(rw);
    });
  }

  Future<List<WilRt>> getRt(int idRw) async {
    final resp = await _request("${URL.wilayahRt}$idRw", GET);
    List rtList = resp["data"];
    return List.generate(rtList.length, (i) => WilRt.fromJson(rtList[i]));
  }

  Future<Map> _request(
    String path,
    String method, {
    Map? data,
    Map<String, dynamic>? headers,
    bool? debug,
  }) async {
    Map resp = {};
    session.options.method = method;
    session.options.responseType = ResponseType.plain;

    if (headers != null) {
      session.options.headers = headers;
    }

    try {
      final response = await session.request(path, data: data);
      if (debug ?? false) {
        print(response.toString());
      }

      try {
        resp = {"status": 200, "data": json.decode(response.toString())};
      } on FormatException {
        resp = {"status": 200, "data": response.toString()};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        try {
          resp = json.decode(e.response!.data);
          resp['status'] = int.tryParse(resp['status']);
        } on FormatException {
          resp = {
            "status": e.response!.statusCode,
            "message": e.response!.statusMessage,
          };
        }
      } else {
        if (e.type == DioExceptionType.receiveTimeout) {
          resp = {"status": 504, "message": e.message};
        } else if (e.type == DioExceptionType.sendTimeout) {
          resp = {"status": 408, "message": e.message};
        } else if (e.type == DioExceptionType.connectionTimeout) {
          resp = {"status": 408, "message": e.message};
        } else if (e.type == DioExceptionType.connectionError) {
          resp = {"status": 408, "message": e.message};
        } else {
          resp = {"status": 0, "message": "unknown error"};
        }

        var message = apiStatus[resp['status']] ?? "gatau kenapa";
        showError(message);
        print(resp['message']);
      }
    }
    return resp;
  }

  void showLoading({String? message, required BuildContext context}) {
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
