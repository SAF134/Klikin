# AI Agents Operating Manual & Rules of Engagement (AGENTS.md) — Klikin

* **Aplikasi:** Klikin (Android Auto-Clicker & Automation)
* **Target Audience:** Seluruh AI Agents (Claude, GPT, Gemini, Cursor, Antigravity) yang memodifikasi codebase ini
* **Otoritas:** AI Engineering Lead & Lead Software Architect
* **Dokumen Versi:** 1.0.0
* **Status:** Aktif & Wajib Dipatuhi Tanpa Pengecualian

---

## 1. Golden Rules (Pantangan Keras & Non-Negotiable Constraints)

Setiap AI Agent yang melanggar salah satu dari 6 aturan mutlak ini dianggap menghasilkan kode rusak (*corrupt/rejected*):

1. **Dilarang Menjalankan Flutter Engine Kedua untuk Overlay:**
   * Seluruh panel kontrol melayang (*Floating Dock*) dan *Target Pins* **wajib 100% menggunakan Native Android View (XML + WindowManager di Kotlin)**. 
   * Dilarang keras mencoba menggunakan `FlutterEngineGroup` atau *Add-to-App* untuk overlay karena memakan RAM $> 80\text{ MB}$ dan rawan crash saat game berjalan berat.
2. **Dilarang Mengizinkan Interval Waktu di Bawah $25\text{ ms}$:**
   * Di layer Dart (UI) maupun layer Kotlin (Native Engine), jeda antar ketukan minimal terkunci ketat pada **$25\text{ ms}$** (`coerceAtLeast(25L)`). Tidak ada toleransi untuk bypass batas ini demi mencegah *InputQueue overflow* dan *kernel freeze*.
3. **Dilarang Mengaktifkan `canRetrieveWindowContent="true"`:**
   * File `accessibility_service_config.xml` **wajib mempertahankan `canRetrieveWindowContent="false"`**. Klikin hanya melakukan injeksi koordinat spasial ($X, Y$), bukan membaca data/teks layar pengguna.
4. **Dilarang Mengubah Signature Platform Channel Tanpa Izin:**
   * Nama method, parameter input, dan struktur JSON pada `MethodChannel` (`com.klikin.app/controller`) dan `EventChannel` (`com.klikin.app/events`) **harus identik 100% dengan [ARCHITECTURE.md](file:///c:/Proyek%20Mandiri/Klikin/ARCHITECTURE.md)**. Jangan pernah menambah atau mengganti tipe data method tanpa memperbarui dokumen arsitektur terlebih dahulu.
5. **Dilarang Mengekspos Komponen Internal Android:**
   * Seluruh Service dan Receiver di `AndroidManifest.xml` wajib memiliki atribut `android:exported="false"` untuk mencegah serangan *Confused Deputy*.
6. **Dilarang Mengubah File di Luar Scope Task yang Sedang Dikerjakan:**
   * Jangan melakukan *unsolicited refactoring* pada file yang tidak berkaitan dengan task aktif saat itu.

---

## 2. Standar Kode & Konvensi Bahasa

### 2.1 Standar Dart & Flutter
* **Clean Architecture & Separation of Concerns:**
  * UI (`lib/presentation/`) hanya boleh merender state dan mengirimkan event.
  * Logika bisnis murni wajib berada di dalam BLoC (`flutter_bloc`). Dilarang menaruh logika manipulasi data langsung di dalam `StatefulWidget.setState`.
* **Immutability & Data Modeling:**
  * Seluruh kelas entity dan model data wajib *immutable* (`@immutable`) dan meng-extend `Equatable` untuk mencegah rebuild widget yang tidak perlu.
* **Typing & Null-Safety:**
  * Dilarang menggunakan tipe `dynamic` kecuali saat menerima payload mentah dari `MethodCallHandler`. Segera parse ke model strongly-typed.
  * Hindari penggunaan bang operator (`!`) secara serampangan. Selalu gunakan *null-aware operators* (`?.`, `??`) atau *guard clauses*.
* **Design Token Consistency:**
  * Dilarang keras melakukan hardcoded warna hex di dalam file widget. Seluruh styling wajib merujuk ke token di `lib/core/theme/` (`AppColors`, `AppTypography`, `AppSpacing`).

### 2.2 Standar Kotlin & Android Native
* **Coroutines Over Raw Threads:**
  * Dilarang menggunakan `Thread.sleep()` atau `java.lang.Thread`. Seluruh operasi jeda waktu gestur dan asinkron wajib menggunakan Kotlin Coroutines (`delay()`) dengan scope `CoroutineScope(Dispatchers.Default + SupervisorJob())`.
* **Zero Memory Leak pada WindowManager:**
  * Setiap view yang di-attach via `WindowManager.addView()` wajib memiliki mekanisme pembersihan yang dijamin terpanggil saat service mati (`removeViewImmediate()` di dalam `onDestroy()`).
  * Jangan pernah menyimpan instance `Context` (terutama Activity Context) di dalam `companion object` atau variabel statis.
* **Defensive Boundary Clamping:**
  * Setiap koordinat $(X, Y)$ yang diterima dari antarmuka pengguna wajib melalui `CoordinateSanitizer` sebelum diumpankan ke `Path()` atau `GestureDescription`.

---

## 3. Protokol Alur Kerja AI Agent (Execution Loop)

Setiap kali Anda menerima instruksi untuk melanjutkan proyek, ikuti siklus 5 langkah ini secara disiplin:

```mermaid
flowchart TD
    A[1. Baca TASKS.md] --> B[2. Identifikasi Task Teratas yang Masih PENDING]
    B --> C[3. Tulis Kode Minimal Sesuai Acceptance Criteria Task Tersebut]
    C --> D[4. Eksekusi Perintah Verifikasi di Terminal]
    D --> E{Apakah Lolos?}
    E -->|Gagal: Perbaiki Error| C
    E -->|Lolos| F[5. Tandai Task Menjadi [x] di TASKS.md & Buat Laporan]
```

### Langkah-Langkah Operasional:
1. **Periksa Status:** Buka [TASKS.md](file:///c:/Proyek%20Mandiri/Klikin/TASKS.md). Cari task pertama yang masih berstatus `- [ ]`.
2. **Kunci Scope:** Batasi modifikasi kode hanya pada file yang diminta oleh task tersebut. Jangan melompat ke task di fase berikutnya.
3. **Eksekusi & Verifikasi Mandiri:** Setelah menulis atau mengedit file, **jalankan perintah verifikasi** yang tertera di task tersebut (misal: `flutter analyze`, `flutter test`, atau compile check).
4. **Update Status Dokumen:** Jika verifikasi lolos, ubah status task pada `TASKS.md` dari `- [ ]` menjadi `- [x]`.
5. **Transparansi:** Laporkan kepada pengguna file apa saja yang dibuat/diubah dan hasil perintah verifikasinya secara ringkas dan lugas.

---

## 4. Penanganan Error & Konflik

* **Jika Dependensi Rusak / Konflik Versi:**
  * Jangan menebak-nebak versi paket secara acak. Periksa dokumentasi resmi pub.dev atau gunakan `flutter pub add <nama_paket>` untuk membiarkan Flutter menyelesaikan kompatibilitas transitive dependencies.
* **Jika Muncul Perbedaan Spesifikasi:**
  * Selalu prioritaskan hierarki kebenaran dokumen (*Source of Truth*):
    $$\text{PRD.md} \longrightarrow \text{ARCHITECTURE.md} \longrightarrow \text{SECURITY.md} \longrightarrow \text{DESIGN\_BRIEF.md}$$
  * Jika menemukan kontradiksi yang tidak bisa diatasi sendiri, tanyakan kepada pengguna sebelum mengambil asumsi sepihak.
