# Siga Automator (Aplikasi Flutter)

Siga Automator adalah aplikasi berbasis Flutter yang dirancang untuk membantu kader dan petugas lapangan dalam mengelola aktivitas kelompok masyarakat (Poktan) yang merupakan bagian dari program pembangunan keluarga nasional SIGA (Sistem Informasi Keluarga).

---

## ℹ️ Tentang SIGA

**SIGA (Sistem Informasi Keluarga)** adalah sistem informasi milik **BKKBN (Badan Kependudukan dan Keluarga Berencana Nasional)** yang digunakan untuk mencatat data keluarga, memantau indikator pembangunan keluarga, serta mendukung pelaksanaan program KB dan pembangunan keluarga di seluruh Indonesia.

---

## 🎯 Tujuan Aplikasi

Aplikasi ini bertujuan untuk menyederhanakan alur kerja petugas lapangan, terutama dalam pengisian dan pelaporan data Poktan. Dengan Siga Automator, proses yang biasanya memerlukan banyak langkah (seperti klik berkali-kali) bisa dilakukan lebih cepat dan efisien, serta meminimalkan potensi kesalahan input.

---

## 🔧 Fitur Utama

- Manajemen kelompok (Poktan), mencakup:
  - BKB (Bina Keluarga Balita)
  - BKL (Bina Keluarga Lansia)
  - BKR (Bina Keluarga Remaja)
  - UPPKA (Usaha Peningkatan Pendapatan Keluarga Akseptor)
  - PIK-R (Pusat Informasi dan Konseling Remaja)
- Manajemen dan pendaftaran anggota
- Pencatatan kegiatan menggunakan formulir R1
- Dashboard dengan visualisasi data
- Integrasi dengan SIGA API Gateway (BKKBN)
- Integrasi dengan Supabase
- Dukungan lintas platform: Android dan Windows

---

## 🧱 Arsitektur Aplikasi

- Dibangun dengan **Flutter**, menggunakan **GetX** untuk state management
- Backend menggunakan **Supabase** untuk penyimpanan data dan autentikasi
- Komponen Android native (tidak ditampilkan di sini)
- Struktur kode yang jelas dan modular, termasuk:
  - Lapisan API (`SigaApi`)
  - Manajemen state (`ContextController`, `ThemeController`)
  - Komponen UI dan sistem navigasi

---

## 🚀 Fitur yang Direncanakan

- Perhitungan persentase laporan Poktan
- Statistik kehadiran anggota Poktan
- Analisis kebutuhan KB yang belum terpenuhi per wilayah
- Pelacakan jumlah PUS dan KRS
- Visualisasi tren penggunaan Alkon
- Rekap jumlah akseptor tiap Faskes
- `Tell me your idea!`

---

## 📦 Build & Deployment

- Mendukung platform Android dan Windows
- Konfigurasi menggunakan `environment variable` melalui Gradle dan BuildConfig
- Otomatisasi build menggunakan GitHub Actions dan skrip PowerShell

---

## ⚠️ Catatan

- Gunakan aplikasi ini dengan bijak dan sesuai kebutuhan.
