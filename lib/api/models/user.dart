import 'dart:convert';

import 'package:siga/api/siga_api.dart';

class User {
    String? userId;
    String? userName;
    String? namaLengkap;
    String? noTelepone;
    String? email;
    String? namaLevelWilayah;
    String? token;
    late WilKecamatan wilKecamatan;
    WilKabupaten? wilKabupaten;
    WilProvinsi? wilProvinsi;
    
    Future<bool> get initDone async {
      return wilKecamatan.initDone;
    }

    User({
        this.userId,
        this.userName,
        this.namaLengkap,
        this.noTelepone,
        this.email,
        this.wilKabupaten,
        this.wilProvinsi,
        this.token,
        required SigaApi api,
        Map<String, dynamic>? kecamatan,
    }) {
      postInit(api, kecamatan!);
    }

    Future<void> postInit(api, kecamatan) async {
      kecamatan!['api'] = api;
      wilKecamatan = WilKecamatan.fromJson(kecamatan);
    }

    factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory User.fromJson(Map<String, dynamic> json) {
      return User(
        userId: json["userId"],
        userName: json["userName"],
        namaLengkap: json["namaLengkap"],
        noTelepone: json["noTelepone"],
        email: json["email"],
        kecamatan: json['wilKecamatan'],
        wilKabupaten: WilKabupaten.fromJson(json["wilKabupaten"]),
        wilProvinsi: WilProvinsi.fromJson(json["wilProvinsi"]),
        api: json['api'],
        token: json["token"],
      );
    }

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "userName": userName,
        "namaLengkap": namaLengkap,
        "noTelepone": noTelepone,
        "email": email,
        "wilKecamatan": wilKecamatan.toJson(),
        "wilKabupaten": wilKabupaten?.toJson(),
        "wilProvinsi": wilProvinsi?.toJson(),
    };
}

class WilKabupaten {
    int? idKabupaten;
    String? idKabupatenDepdagri;
    String? namaKabupaten;

    WilKabupaten({
        this.idKabupaten,
        this.idKabupatenDepdagri,
        this.namaKabupaten,
    });

    factory WilKabupaten.fromRawJson(String str) => WilKabupaten.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory WilKabupaten.fromJson(Map<String, dynamic> json) => WilKabupaten(
        idKabupaten: json["id_kabupaten"],
        idKabupatenDepdagri: json["id_kabupaten_depdagri"],
        namaKabupaten: json["nama_kabupaten"],
    );

    Map<String, dynamic> toJson() => {
        "id_kabupaten": idKabupaten,
        "id_kabupaten_depdagri": idKabupatenDepdagri,
        "nama_kabupaten": namaKabupaten,
    };
}

class WilRw {
    int? idRw;
    String? idRwDepdagri;
    String? namaRw;
    List<WilRt> wilRt = [];
    
    bool get initDone {
      if (wilRt.isNotEmpty) {
        for (var rt in wilRt) {
          if (!rt.initDone) {
            return false;
          }
        }
        return true;
      }
      return false;
    }

    WilRw({
        this.idRw,
        this.idRwDepdagri,
        this.namaRw,
        SigaApi? api,
    }) {
      postInit(api!);
    }

    Future<void> postInit(SigaApi api) async {
      wilRt = await api.getRt(idRw!);
    }

    factory WilRw.fromRawJson(String str) => WilRw.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory WilRw.fromJson(Map<String, dynamic> json) => WilRw(
        idRw: json["id_rw"],
        idRwDepdagri: json["id_rw_depdagri"],
        namaRw: json["nama_rw"],
        api: json["api"],
    );

    Map<String, dynamic> toJson() => {
        "id_rw": idRw,
        "id_rw_depdagri": idRwDepdagri,
        "nama_rw": namaRw,
        "wil_rt": List.generate(wilRt.length, (i) => wilRt[i].toJson())
    };
}

class WilRt {
    int? idRt;
    String? idRtDepdagri;
    String? namaRt;
    bool initDone = false;

    WilRt({
        this.idRt,
        this.idRtDepdagri,
        this.namaRt,
    }){
      initDone = true;
    }

    factory WilRt.fromRawJson(String str) => WilRt.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory WilRt.fromJson(Map<String, dynamic> json) => WilRt(
        idRt: json["id_rt"],
        idRtDepdagri: json["id_rt_depdagri"],
        namaRt: json["nama_rt"],
    );

    Map<String, dynamic> toJson() => {
        "id_rt": idRt,
        "id_rt_depdagri": idRtDepdagri,
        "nama_rt": namaRt,
    };
}

class WilKelurahan {
    int? idKelurahan;
    String? idKelurahanDepdagri;
    String? namaKelurahan;
    List<WilRw> wilRw = [];
    
    bool get initDone {
      if (wilRw.isNotEmpty) {
        for (var rw in wilRw) {
          if (!rw.initDone) {
            return false;
          }
        }
        return true;
      }
      return false;
    }

    WilKelurahan({this.idKelurahan, this.idKelurahanDepdagri, this.namaKelurahan, SigaApi? api});

    Future<void> postInit(SigaApi api) async {
      wilRw = await api.getRw(idKelurahan!);
    }

    factory WilKelurahan.fromRawJson(String str) => WilKelurahan.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory WilKelurahan.fromJson(Map<String, dynamic> json) => WilKelurahan(
        idKelurahan: json["id_kelurahan"],
        idKelurahanDepdagri: json["id_kelurahan_depdagri"],
        namaKelurahan: json["nama_kelurahan"],
        api: json["api"],
    );

    Map<String, dynamic> toJson() => {
        "id_kelurahan": idKelurahan,
        "id_keurahan_depdagri": idKelurahanDepdagri,
        "nama_kelurahan": namaKelurahan,
        "wil_rw": List.generate(wilRw.length, (i) => wilRw[i].toJson()),
    };
}

class WilKecamatan {
    int? idKecamatan;
    String? idKecamatanDepdagri;
    String? namaKecamatan;
    List<WilKelurahan> wilKelurahan = [];
    late Future _kelurahanGetter;

    Future<bool> get initDone async {
      await _kelurahanGetter;
      return true;
    }

    WilKecamatan({
        this.idKecamatan,
        this.idKecamatanDepdagri,
        this.namaKecamatan,
        SigaApi? api
    }) {
      _kelurahanGetter = postInit(api!);
    }

    Future<void> postInit(SigaApi api) async {
      wilKelurahan = await api.getKelurahan(idKecamatan!);
    }

    factory WilKecamatan.fromRawJson(String str) => WilKecamatan.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory WilKecamatan.fromJson(Map<String, dynamic> json) => WilKecamatan(
        idKecamatan: json["id_kecamatan"],
        idKecamatanDepdagri: json["id_kecamatan_depdagri"],
        namaKecamatan: json["nama_kecamatan"],
        api: json["api"],
    );

    Map<String, dynamic> toJson() => {
        "id_kecamatan": idKecamatan,
        "id_kecamatan_depdagri": idKecamatanDepdagri,
        "nama_kecamatan": namaKecamatan,
        "wil_kelurahan": List.generate(wilKelurahan.length, (i) => wilKelurahan[i].toJson()),
    };
}

class WilProvinsi {
    int? idProvinsi;
    String? idProvinsiDepdagri;
    String? namaProvinsi;

    WilProvinsi({
        this.idProvinsi,
        this.idProvinsiDepdagri,
        this.namaProvinsi,
    });

    factory WilProvinsi.fromRawJson(String str) => WilProvinsi.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory WilProvinsi.fromJson(Map<String, dynamic> json) => WilProvinsi(
        idProvinsi: int.parse(json["id_provinsi"]),
        idProvinsiDepdagri: json["id_provinsi_depdagri"],
        namaProvinsi: json["nama_provinsi"],
    );

    Map<String, dynamic> toJson() => {
        "id_provinsi": idProvinsi.toString(),
        "id_provinsi_depdagri": idProvinsiDepdagri,
        "nama_provinsi": namaProvinsi,
    };
}