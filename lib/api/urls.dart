class URL {
  static String wilayahProvinsi = _Wilayah.provinsi;
  static String wilayahKabupaten = _Wilayah.kabupaten;
  static String wilayahKecamatan = _Wilayah.kecamatan;
  static String wilayahKelurahan = _Wilayah.kelurahan;
  static String wilayahRw  = _Wilayah.rw;
  static String wilayahRt = _Wilayah.rt;
  static const String poktanList = _Poktan.list;
  static const String poktanDetail = _Poktan.detail;
  static const String poktanListKegiatan = _Poktan.listKegiatan;
  static const String poktanDetailKegiatan = _Poktan.detailKegiatan;
  static const String poktanUpsertKegiatan = _Poktan.upsertKegiatan;
  static const String api = "https://siga-api-gateway.bkkbn.go.id/";
  static const String auth = "/sigaauthorizationservice/auth/signin?";
  static const String parentRekapPK = "/rekapitulasi-data-keluarga/siga/rekap/parentRekapPK?bulan={bulan}&tahun={tahun}&page=1&recordPerPage=10&nik={nik}&nama={nama}&idProvinsi={provinsi}&idKabupaten={kabupaten}&idKecamatan={kecamatan}&idKelurahan={kelurahan}";
  static const String childRekapPK = "/rekapitulasi-data-keluarga/siga/rekap/childRekapPK?bulan={bulan}&tahun={tahun}&noKeluarga={kki}";
}


class _Poktan {
  static const list = "/poktan/siga/poktan/getListPoktan?filterPencarian={param}&jenisPoktan={jenis}";
  static const detail = "/poktan/siga/poktan/getDetailPoktan?id={id}&jenisPoktan={jenis}";
  static const listKegiatan = "/poktan/siga/poktan/getListPoktanKegiatan?id={id}&jenisPoktan={jenis}";
  static const detailKegiatan = "/poktan/siga/poktan/getDetailPoktanKegiatan?id={id}&tanggalKegiatan={tanggal}&jenisPoktan={jenis}";
  static const upsertKegiatan = "/poktan/siga/poktan/upsertPoktanKegiatan?jenisPoktan={jenis}";
}

class _Wilayah {
  static const String _loc = "/location-service/siga/location/getList{0}ById{1}?id_{2}=";
  static final String provinsi = '${_loc.substring(0, 39)}Provinsi';
  
  static final String kabupaten = _loc
    .replaceAll('{0}', 'Kabupaten')
    .replaceAll('{1}', 'Provinsi')
    .replaceAll('{2}', 'provinsi');

  static final String kecamatan = _loc
    .replaceAll('{0}', 'Kecamatan')
    .replaceAll('{1}', 'Kabupaten')
    .replaceAll('{2}', 'kabupaten');
  
  static final String kelurahan = _loc
    .replaceAll('{0}', 'Kelurahan')
    .replaceAll('{1}', 'Kecamatan')
    .replaceAll('{2}', 'kecamatan');
  
  static final String rw = _loc
    .replaceAll('{0}', 'Rw')
    .replaceAll('{1}', 'Kelurahan')
    .replaceAll('{2}', 'kelurahan');
  
  static final String rt = _loc
    .replaceAll('{0}', 'Rt')
    .replaceAll('{1}', 'Rw')
    .replaceAll('{2}', 'rw');
}