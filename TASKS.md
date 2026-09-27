# Implementation Work Breakdown Structure (TASKS.md) — Klikin

* **Aplikasi:** Klikin (Android Auto-Clicker & Automation)
* **Status:** Actionable Implementation Backlog
* **Role:** Technical Project Manager / Scrum Master
* **Dokumen Versi:** 1.0.0

---

## Ringkasan Progres Implementasi

| Fase | Deskripsi | Status | Estimasi Tasks | Selesai |
| :--- | :--- | :---: | :---: | :---: |
| **Fase 1** | Scaffolding, Dependency Setup & Android Security Manifest | `COMPLETED` | 5 Tasks | 5 / 5 |
| **Fase 2** | Native AccessibilityService & Gesture Engine (Kotlin) | `COMPLETED` | 4 Tasks | 4 / 4 |
| **Fase 3** | Native Floating WindowManager Overlay (Kotlin XML) | `COMPLETED` | 5 Tasks | 5 / 5 |
| **Fase 4** | MethodChannel Platform Bridge (Dart $\leftrightarrow$ Kotlin) | `COMPLETED` | 4 Tasks | 4 / 4 |
| **Fase 5** | Flutter UI, State Management & Profile Persistence (Hive) | `COMPLETED` | 6 Tasks | 6 / 6 |
| **Fase 6** | Integration, Failsafe Hardening & Performance Benchmarking | `COMPLETED` | 5 Tasks | 5 / 5 |
| **TOTAL** | | | **29 Tasks** | **29 / 29** |

---

## FASE 1: Scaffolding, Dependency Setup & Android Security Manifest

- [x] **Task 1.1: Inisialisasi Project Flutter Android-Only**
  * **Deskripsi:** Inisialisasi project Flutter di workspace dengan package `com.klikin.app`, bahasa Android Kotlin, dan hapus folder non-Android (`ios`, `web`, `windows`, `linux`, `macos`).
  * **Acceptance Criteria:** Project terinisialisasi bersih, `android/` berkonfigurasi Kotlin, folder platform lain terhapus.
  * **Perintah Verifikasi:**
    ```bash
    flutter create --org com.klikin.app -a kotlin --platforms android .
    flutter doctor -v
    ```

- [x] **Task 1.2: Konfigurasi Dependensi `pubspec.yaml`**
  * **Deskripsi:** Tambahkan pustaka inti ke `pubspec.yaml`: `flutter_bloc`, `hive`, `hive_flutter`, `flutter_secure_storage`, `google_fonts`, `uuid`, dan `equatable`.
  * **Acceptance Criteria:** `flutter pub get` selesai dengan exit code 0 tanpa konflik versi dependensi.
  * **Perintah Verifikasi:**
    ```bash
    flutter pub get
    ```

- [x] **Task 1.3: Konfigurasi Keamanan `AndroidManifest.xml`**
  * **Deskripsi:** Tambahkan permission `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `WAKE_LOCK`. Daftarkan `KlikinAccessibilityService` dan `OverlayControllerService` dengan atribut keamanan `android:exported="false"` dan `android:allowBackup="false"`.
  * **Acceptance Criteria:** Manifest valid, tidak ada syntax error, seluruh service berstatus private sesuai [SECURITY.md](file:///c:/Proyek%20Mandiri/Klikin/SECURITY.md).
  * **Perintah Verifikasi:**
    ```bash
    grep -E "exported=\"false\"" android/app/src/main/AndroidManifest.xml
    ```

- [x] **Task 1.4: Konfigurasi XML Aksesibilitas (`accessibility_service_config.xml`)**
  * **Deskripsi:** Buat file `android/app/src/main/res/xml/accessibility_service_config.xml` dengan `canPerformGestures="true"`, `canRetrieveWindowContent="false"`, dan `canRequestFilterKeyEvents="true"`.
  * **Acceptance Criteria:** File XML tercipta dengan flag privasi anti-kebocoran layar aktif.
  * **Perintah Verifikasi:**
    ```bash
    cat android/app/src/main/res/xml/accessibility_service_config.xml
    ```

- [x] **Task 1.5: Setup Struktur Folder Sesuai Blueprint Arsitektur**
  * **Deskripsi:** Buat direktori lengkap di `lib/` (core, data, domain, presentation, services) dan di Kotlin `android/app/src/main/kotlin/com/klikin/app/` (bridge, service, overlay, engine, model).
  * **Acceptance Criteria:** Struktur direktori 100% cocok dengan [ARCHITECTURE.md](file:///c:/Proyek%20Mandiri/Klikin/ARCHITECTURE.md).
  * **Perintah Verifikasi:**
    ```powershell
    Get-ChildItem -Directory lib, android/app/src/main/kotlin/com/klikin/app
    ```

---

## FASE 2: Native AccessibilityService & Gesture Engine (Kotlin)

- [x] **Task 2.1: Implementasi Lifecycle `KlikinAccessibilityService.kt`**
  * **Deskripsi:** Implementasikan subclass `AccessibilityService` dengan listener koneksi service, penyimpanan instance singleton/companion untuk akses internal, dan pembersihan resource saat service mati.
  * **Acceptance Criteria:** Service berhasil bind saat diaktifkan di Android Settings dan mencatat status aktif.
  * **Perintah Verifikasi:**
    ```bash
    ./gradlew compileDebugKotlin
    ```

- [x] **Task 2.2: Implementasi `GestureDispatcherEngine.kt`**
  * **Deskripsi:** Bangun engine injeksi ketukan menggunakan Coroutines (`Dispatchers.Default`), konstruksi `Path` dan `GestureDescription.StrokeDescription`, serta callback `AccessibilityService.GestureResultCallback`.
  * **Acceptance Criteria:** Fungsi `dispatchTap(x, y, durationMs)` mengembalikan boolean sukses tanpa memblokir UI thread.
  * **Perintah Verifikasi:**
    Unit test Kotlin untuk memastikan gesture builder mengembalikan koordinat yang tepat.

- [x] **Task 2.3: Implementasi Boundary Sanitizer (`CoordinateSanitizer.kt`)**
  * **Deskripsi:** Bangun utilitas sanitasi koordinat untuk mengunci koordinat $X, Y$ ke dimensi layar fisik aktif, membatasi interval minimal $\ge 25\text{ ms}$, dan durasi tekan minimal $\ge 20\text{ ms}$.
  * **Acceptance Criteria:** Koordinat negatif atau nilai di luar resolusi layar otomatis di-clamp tanpa memicu crash.
  * **Perintah Verifikasi:**
    Unit test `CoordinateSanitizerTest.kt` dengan input nilai batas ekstrem (-100, 99999, delay 5ms).

- [x] **Task 2.4: Implementasi Hardware Emergency Killswitch (`onKeyEvent`)**
  * **Deskripsi:** Tangkap event `KeyEvent.KEYCODE_VOLUME_DOWN` pada `KlikinAccessibilityService.onKeyEvent()`. Saat terdeteksi dan eksekusi sedang aktif, batalkan Coroutine Job seketika dan set state menjadi `PAUSED`.
  * **Acceptance Criteria:** Menekan Volume Down membatalkan loop ketukan dalam waktu $< 100\text{ ms}$ dan event dikonsumsi (`return true`).
  * **Perintah Verifikasi:**
    Manual test di emulator/device dengan memantau log trigger killswitch.

---

## FASE 3: Native Floating WindowManager Overlay (Kotlin XML)

- [x] **Task 3.1: Desain Layout XML Native Sesuai Design Tokens**
  * **Deskripsi:** Buat layout XML di `android/app/src/main/res/layout/`:
    - `view_floating_dock.xml` (Panel vertikal expanded)
    - `view_floating_dock_min.xml` (Panel ciut / bubble)
    - `view_target_pin.xml` (Lingkaran nomor target $40\times40\text{ dp}$ dual-ring)
    - `colors.xml` (Palette Obsidian, Slate, Electric Emerald `#00E599`, Cyan `#00C2FF`).
  * **Acceptance Criteria:** Seluruh layout XML valid dan tombol memenuhi dimensi target sentuh minimal $48\times48\text{ dp}$.
  * **Perintah Verifikasi:**
    ```bash
    ./gradlew assembleDebug
    ```

- [x] **Task 3.2: Implementasi `FloatingWindowManager.kt`**
  * **Deskripsi:** Bangun kelas pembungkus `WindowManager` untuk menangani penambahan, pembaruan posisi, dan penghapusan view dengan flag `TYPE_APPLICATION_OVERLAY`.
  * **Acceptance Criteria:** View dapat ditambahkan dan dihapus secara aman tanpa crash `WindowManager.BadTokenException`.
  * **Perintah Verifikasi:**
    Verifikasi kode bebas dari memory leak saat `destroy()` dipanggil.

- [x] **Task 3.3: Implementasi Controller Dock Melayang (`FloatingDockView.kt`)**
  * **Deskripsi:** Buat interaksi gesture drag pada drag-handle dock, tombol Play/Pause toggle, Add/Remove target, tombol Minimize ke bubble, dan tombol Close total.
  * **Acceptance Criteria:** Dock dapat digeser mulus ke seluruh layar, aksi drag tidak memicu tombol klik, state tombol Play berganti warna Emerald saat aktif.
  * **Perintah Verifikasi:**
    Uji manual drag dan minimize/expand di layar Android.

- [x] **Task 3.4: Implementasi Target Pin & Touch-Passthrough (`TargetPinView.kt`)**
  * **Deskripsi:** Buat view pin bernomor urut 1, 2, 3.. yang draggable. Implementasikan pergantian dinamis flag `FLAG_NOT_TOUCHABLE`: saat running flag aktif (touch tembus), saat pause flag mati (bisa di-drag).
  * **Acceptance Criteria:** Pin dapat diposisikan manual saat pause, dan ketukan tembus ke aplikasi di bawah pin saat running.
  * **Perintah Verifikasi:**
    Verifikasi pengetukan tembus ke tombol di bawah pin saat mode running.

- [x] **Task 3.5: Implementasi Foreground Service (`OverlayControllerService.kt`)**
  * **Deskripsi:** Buat foreground service dengan persistent notification bertuliskan "Klikin sedang aktif di latar belakang" lengkap dengan tombol aksi darurat "STOP" di notification tray.
  * **Acceptance Criteria:** Service berjalan sebagai foreground service resmi Android (`START_STICKY`) dan tidak mudah di-kill oleh OS.
  * **Perintah Verifikasi:**
    ```bash
    adb shell dumpsys activity services com.klikin.app
    ```

---

## FASE 4: MethodChannel Platform Bridge (Dart $\leftrightarrow$ Kotlin)

- [x] **Task 4.1: Implementasi Handler Platform Channel Native (Kotlin)**
  * **Deskripsi:** Implementasikan `NativeMethodHandler.kt` dan `NativeStreamHandler.kt` di `MainActivity.kt` untuk menangani 10 method dan event stream sesuai [ARCHITECTURE.md](file:///c:/Proyek%20Mandiri/Klikin/ARCHITECTURE.md).
  * **Acceptance Criteria:** Seluruh method menerima payload JSON dan mengembalikan hasil/error code yang sesuai.
  * **Perintah Verifikasi:**
    Unit test bridge serialization.

- [x] **Task 4.2: Implementasi Platform Bridge Service di Flutter (Dart)**
  * **Deskripsi:** Buat kelas singleton `PlatformBridgeService.dart` sebagai abstraction layer tipis untuk `MethodChannel('com.klikin.app/controller')` dan `EventChannel('com.klikin.app/events')`.
  * **Acceptance Criteria:** Memiliki fungsi strongly-typed untuk setiap pemanggilan native dan stream broadcast untuk event.
  * **Perintah Verifikasi:**
    ```bash
    flutter test test/services/platform_bridge_service_test.dart
    ```

- [x] **Task 4.3: Implementasi Verifikasi Izin Sistem**
  * **Deskripsi:** Hubungkan pengecekan `checkPermissions()`, `requestOverlayPermission()`, dan `requestAccessibilityPermission()` dari Flutter ke Android Native Intent settings.
  * **Acceptance Criteria:** Membuka layar Android Settings yang relevan dan mendeteksi perubahan status izin saat kembali ke aplikasi.
  * **Perintah Verifikasi:**
    Verifikasi alur toggle izin di real device / emulator.

- [x] **Task 4.4: Implementasi Sinkronisasi Koordinat & State Real-Time**
  * **Deskripsi:** Hubungkan sinkronisasi target saat pengguna menggeser pin di layar native agar koordinat terbarunya dikirimkan kembali ke Flutter state melalui EventChannel.
  * **Acceptance Criteria:** Koordinat $X, Y$ di Flutter state selalu up-to-date dengan posisi fisik pin di layar.
  * **Perintah Verifikasi:**
    Log verifikasi aliran event koordinat di terminal debugger.

---

## FASE 5: Flutter UI, State Management & Profile Persistence (Hive)

- [x] **Task 5.1: Setup Desain Token, Tipografi, dan Dark Theme**
  * **Deskripsi:** Definisikan `AppColors` (`#0B0E14`, `#151922`, `#00E599`, dll), `AppTypography` (`Plus Jakarta Sans` dan `JetBrains Mono`), serta `AppTheme` di `lib/core/theme/`.
  * **Acceptance Criteria:** Seluruh token warna dan font terdefinisi sesuai [DESIGN_BRIEF.md](file:///c:/Proyek%20Mandiri/Klikin/DESIGN_BRIEF.md).
  * **Perintah Verifikasi:**
    ```bash
    flutter analyze
    ```

- [x] **Task 5.2: Model Data & Enkripsi Storage Lokal (Hive + Keystore)**
  * **Deskripsi:** Buat model `ClickProfile`, `TargetPoint`, `LoopConfig` dengan Hive TypeAdapter. Setup enkripsi box Hive menggunakan AES cipher dari `flutter_secure_storage`.
  * **Acceptance Criteria:** Data profil dapat di-serialize/deserialize dengan aman ke disk internal sandbox (`Context.MODE_PRIVATE`).
  * **Perintah Verifikasi:**
    ```bash
    flutter test test/data/profile_repository_test.dart
    ```

- [x] **Task 5.3: Implementasi BLoC State Management**
  * **Deskripsi:** Buat `PermissionBloc`, `ProfileBloc`, dan `ServiceBloc` menggunakan `flutter_bloc` dengan pemisahan Event, State, dan Handler yang jelas.
  * **Acceptance Criteria:** Seluruh state transition teruji dan bebas dari unhandled exceptions.
  * **Perintah Verifikasi:**
    ```bash
    flutter test test/presentation/bloc/
    ```

- [x] **Task 5.4: Membangun Komponen Reusable UI (PillButton & Stepper)**
  * **Deskripsi:** Buat widget reusable `PillButton` ($52\text{ dp}$ height, haptic feedback) dan `MillisecondStepper` dengan quick chips presisi ($50\text{ ms}$, $100\text{ ms}$, $250\text{ ms}$, $500\text{ ms}$, $1\text{ s}$).
  * **Acceptance Criteria:** Komponen patuh terhadap minimum touch target $48\times48\text{ dp}$ dan tidak ada overflow layout.
  * **Perintah Verifikasi:**
    Widget test Flutter untuk interaksi tombol dan stepper.

- [x] **Task 5.5: Membangun Layar Dashboard (SCR-01) & Permission Wizard (SCR-02)**
  * **Deskripsi:** Buat antarmuka utama `DashboardScreen` (status izin, mode selector, active profile card, tombol Mulai Panel Melayang) dan modal `PermissionWizardScreen`.
  * **Acceptance Criteria:** Tampilan 100% presisi dengan layout wireframe pada [DESIGN_BRIEF.md](file:///c:/Proyek%20Mandiri/Klikin/DESIGN_BRIEF.md), status izin otomatis recheck saat app resume.
  * **Perintah Verifikasi:**
    Uji render UI pada emulator Android.

- [x] **Task 5.6: Membangun Layar Pengelolaan Profil (SCR-03 & SCR-04)**
  * **Deskripsi:** Bangun layar daftar profil `ProfilePresetScreen` (maksimal 5 slot profil) dan editor detail `ProfileDetailScreen` (reorder target, ubah loop mode, delay per target).
  * **Acceptance Criteria:** Pengguna dapat membuat, memilih, mengedit, dan menghapus profil preset dengan limit maksimal 5 slot.
  * **Perintah Verifikasi:**
    Uji alur CRUD profil lokal.

---

## FASE 6: Integration, Failsafe Hardening & Performance Benchmarking

- [x] **Task 6.1: Verifikasi Integrasi End-to-End Onboarding & Permission**
  * **Deskripsi:** Lakukan pengujian langsung dari status aplikasi fresh install, pandu aktivasi 2 izin hingga indikator berubah hijau, dan pastikan tidak ada looping crash.
  * **Acceptance Criteria:** Onboarding berhasil 100% pada perangkat Android 7.0 hingga Android 14+.
  * **Perintah Verifikasi:**
    Manual E2E run pada device target.

- [x] **Task 6.2: Verifikasi Eksekusi Single & Multi-Point Tap**
  * **Deskripsi:** Letakkan 1 target pin dan rangkaian 3 target pin di atas aplikasi target pengujian. Jalankan eksekusi dan validasi bahwa ketukan terkirim secara berurutan dan akurat.
  * **Acceptance Criteria:** Ketukan diterima oleh aplikasi target dengan ritme fixed interval stabil (toleransi deviasi $\le 10\text{ ms}$).
  * **Perintah Verifikasi:**
    Gunakan aplikasi touch-counter eksternal untuk menghitung akurasi ketukan.

- [x] **Task 6.3: Verifikasi Failsafe & Emergency Stop**
  * **Deskripsi:** Uji skenario darurat: Tekan tombol fisik Volume Down saat klik sedang berjalan cepat, matikan layar ponsel (`ACTION_SCREEN_OFF`), dan simulasikan rotasi layar landscape $\leftrightarrow$ portrait.
  * **Acceptance Criteria:** Seluruh loop langsung terhenti seketika, pin target di-clamp ke batas layar aktif, ponsel tidak pernah mengalami touch lockout.
  * **Perintah Verifikasi:**
    Uji coba interupsi fisik pada device uji.

- [x] **Task 6.4: Stress Test 10.000 Ketukan Berturut-Turut**
  * **Deskripsi:** Jalankan Klikin pada mode loop 10.000 ketukan kontinu di atas game/aplikasi target. Pantau log sistem untuk mendeteksi ANR atau service crash.
  * **Acceptance Criteria:** Mencapai 10.000 ketukan berturut-turut tanpa force close, tanpa service recreation, dan tanpa ANR.
  * **Perintah Verifikasi:**
    ```bash
    adb logcat -s KlikinAccessibilityService:V | grep -E "Loop finished|ANR"
    ```

- [x] **Task 6.5: Resource & Memory Profiling (Ambang Batas < 60 MB)**
  * **Deskripsi:** Ukur alokasi memori (PSS RAM) aplikasi Klikin saat background service dan floating overlay aktif di atas game menggunakan perintah `dumpsys meminfo`.
  * **Acceptance Criteria:** Total PSS RAM aplikasi Klikin berada ketat di bawah $60\text{ MB}$ ($< 60\text{ MB}$).
  * **Perintah Verifikasi:**
    ```bash
    adb shell dumpsys meminfo com.klikin.app
    ```

