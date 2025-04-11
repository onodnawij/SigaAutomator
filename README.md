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

> Gunakan aplikasi ini dengan bijak dan sesuai kebutuhan.

---

<details>
<summary>📄 English Version</summary>

<br>

# Siga Automator (Flutter App)

Siga Automator is a Flutter-based application designed to assist field workers and community facilitators in managing Poktan (community group) activities as part of the national family development program under SIGA (Sistem Informasi Keluarga).

---

## ℹ️ About SIGA

**SIGA (Sistem Informasi Keluarga)** is an information system owned by **BKKBN (Badan Kependudukan dan Keluarga Berencana Nasional)** used to record family data, monitor family development indicators, and support the implementation of family planning and development programs across Indonesia.

---

## 🎯 Purpose of the App

This app aims to simplify the workflow of field officers, especially in recording and reporting Poktan data. With Siga Automator, tasks that typically require many steps (such as multiple clicks) can be done faster, more efficiently, and with fewer input errors.

---

## 🔧 Main Features

- Management of Poktan, including:
  - BKB (Bina Keluarga Balita)
  - BKL (Bina Keluarga Lansia)
  - BKR (Bina Keluarga Remaja)
  - UPPKA (Usaha Peningkatan Pendapatan Keluarga Akseptor)
  - PIK-R (Pusat Informasi dan Konseling Remaja)
- Member registration and management
- Activity logging using R1 forms
- Dashboard with data visualizations
- Integration with SIGA API Gateway (BKKBN)
- Integration with Supabase
- Cross-platform support: Android and Windows

---

## 🧱 Application Architecture

- Built with **Flutter**, using **GetX** for state management
- Backend powered by **Supabase** for data storage and authentication
- Native Android components (not shown here)
- Clean and modular code structure, including:
  - API layer (`SigaApi`)
  - State management (`ContextController`, `ThemeController`)
  - UI components and navigation system

---

## 🚀 Planned Features

- Calculation of Poktan reporting completion percentage
- Attendance statistics for Poktan members
- Unmet needs analysis per region
- Tracking of PUS and KRS counts
- Visualization of Alkon usage trends
- Summary of acceptor counts per facility
- `Tell me your idea!`

---

## 📦 Build & Deployment

- Supports Android and Windows platforms
- Configuration via `environment variable` using Gradle and BuildConfig
- Automated builds using GitHub Actions and PowerShell scripts

---

## ⚠️ Notes

> Use this app wisely and according to your needs.

</details>
