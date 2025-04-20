import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:version/version.dart';


Version appVersion = Version.parse('1.0.0');


const List<String> supportedRoute = [
  "poktan/bkb/register",
  "poktan/bkl/register",
  "poktan/bkb/anggota",
];


List<String> poktanList = ['bkb', 'bkr', 'bkl', 'uppka', 'pik-r'];
List<String> ppkbdList = ['PPKBD', 'Sub PPKBD', 'TPK'];
List<String> toolList = ['tool1', 'tool2', 'tool3'];

Map<int, String> apiStatus = {504: "SIGA lagi ucak", 408: "Koneksimu lagi ucak?"};
Duration requestTimeOutDuration = Duration(seconds: 60);

const Function appFont = GoogleFonts.poppinsTextTheme;

const List<Locale> appLocales = [Locale('en', 'US'), Locale('id', 'ID')];

enum AppOptions {logout, settings, about}

const EdgeInsets appActionsPadding = EdgeInsets.only(right: 10);
PopupMenuButton appOptions (context) {
  return PopupMenuButton(
    color: Theme.of(context).colorScheme.surfaceBright,
    onSelected: (value) {
      String path = '/';

      switch (value) {
        case AppOptions.logout:
          path = '/login';
        case AppOptions.settings:
          path = '/setting';
        case AppOptions.about:
          path = '/about';
      }

      Navigator.of(context).pushNamed(path);
      
    },
    itemBuilder: (context) => <PopupMenuEntry<AppOptions>>[
    PopupMenuItem<AppOptions>(
      value: AppOptions.settings,
      child: const ListTile(
        title: Text('Settings'),
        leading: Icon(Icons.settings),
      )
    ),
    const PopupMenuItem<AppOptions>(
      value: AppOptions.about,
      child: ListTile(
        title: Text('About'),
        leading: Icon(Icons.info),
      )
    ),
    const PopupMenuItem<AppOptions>(
      value: AppOptions.logout,
      child: ListTile(
        title: Text('Logout'),
        leading: Icon(Icons.logout),
      )
    ),
  ]);
}

const Map narsumPoktan = {
  "PKBPLKB": "Penyuluh KB / PLKB",
  "PPLKB": "PPLKB",
  "PPKBD": "PPKBD",
  "SubPPKBD": "Sub PPKBD",
};

const Map materiPoktan = {
  'bkb': [
    "",
    "Menjadi Orangtua Hebat (Usia 0-6 Tahun)",
    "Menjadi Orangtua Hebat dalam Mengasuh Anak (6-10) Tahun",
    "Pengasuhan 1.000 HPK",
    "Penanaman Nilai Karakter melalui 8 Fungsi Keluarga",
    "Peran Ayah Dalam Pengasuhan",
    "Buku Saku Penanaman Nilai Kesadaran Hukum Bagi Keluarga Sejak Dini",
    "Pengasuhan Anak Umur 0-6 Tahun bagi Orang Tua Yang Bekerja",
    "Modul BKB HI",
    "Modul BKB Emas",
    "KIE KB Dan Kesehatan Reproduksi",
  ],
  'bkl': [
    "",
    "Konsep Dasar Lansia Tangguh",
    "Dimensi Lansia Tangguh Dimensi Spiritual",
    "Pembangunan Lansia Tangguh Dimensi Intelektual",
    "Pembangunan Lansia Tangguh Dimensi Fisik",
    "Pembangunan Lansia Tangguh Dimensi Emosional",
    "Pembangunan Lansia Tangguh Dimensi Sosial Kemasyarakatan",
    "Pembangunan Lansia Tangguh Dimensi Profesional Vokasional",
    "Pembangunan Lansia Tangguh Dimensi Lingkungan",
    "Pedoman Perawatan Jangka Panjang (PJP) bagi Lansia Berbasis Keluarga",
    "Menyiapkan Pra Lansia Menjadi Lansia Tangguh",
    "Panduan Praktis Keluarga dalam Mendampingi Lansia (Perawatan Gigi & Mulut serta Nutrisi",
    "KIE KB dan Kesehatan Reproduksi",
  ],
};

const String accessibilityGuide = '''
Tekan **Buka Pengaturan** untuk membuka pengaturan Accessibility.

---

**Cara Mengaktifkan:**
1. Setelah masuk pengaturan Accessibility, Cari dan pilih **Siga Automator**.
2. Aktifkan layanan **Siga Automator**.
3. Konfirmasi jika ada jendela pop-up yang muncul.

---

**Notes:**

- Untuk menemukan layanan **Siga Automator**, di beberapa Brand smartphone kamu perlu masuk ke menu seperti:
  - **Downloaded Apps**
  - **Installed Apps**
  - **Installed Services**
- Pada beberapa Brand smartphone, kamu harus mencentang **"I understand the risk"** atau **"Saya mengerti risikonya"** di jendela konfirmasi sebelum dapat mengaktifkan layanan.
''';