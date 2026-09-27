# Quality Assurance & Performance Testing Guide (TESTING.md) — Klikin

* **Aplikasi:** Klikin (Android Auto-Clicker & Automation)
* **Target OS:** Android 7.0+ (API Level 24+)
* **Role:** Lead QA Automation & Performance Engineer
* **Dokumen Versi:** 1.0.0
* **Status:** Master QA & Benchmark Protocol

---

## 1. Matrix Pengujian Fungsional

Matrix ini mencakup seluruh skenario validasi fitur inti pada rilis MVP Klikin.

| Test Case ID | Fitur / Modul | Pre-Kondisi | Langkah Pengujian | Hasil yang Diharapkan (Expected Result) | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **TC-PERM-01** | Dual Permission Wizard | Fresh install, kedua izin nonaktif. | 1. Buka aplikasi Klikin.<br>2. Ketuk "Setup Sekarang".<br>3. Aktifkan izin "Draw Over Other Apps".<br>4. Kembali ke aplikasi. | Status Overlay berubah hijau (Aktif), tombol berlanjut ke izin Aksesibilitas. | `PASS` |
| **TC-PERM-02** | Accessibility Activation | Izin Overlay aktif, Aksesibilitas nonaktif. | 1. Ketuk tombol aktivasi Aksesibilitas.<br>2. Cari "Klikin" di menu Settings.<br>3. Nyalakan switch dan konfirmasi dialog peringatan.<br>4. Kembali ke aplikasi. | Status Aksesibilitas berubah hijau. Tombol "Mulai Panel Melayang" aktif. | `PASS` |
| **TC-CLICK-01** | Single-Point Tap Loop | Kedua izin aktif, overlay tampil di layar. | 1. Pilih mode "Single-Point".<br>2. Posisikan Pin 1 di atas aplikasi target.<br>3. Atur interval $350\text{ ms}$.<br>4. Tekan tombol Play. | Pin 1 berubah non-touchable, ketukan menembus ke aplikasi target tiap $350\text{ ms}$, icon dock berubah jadi Pause. | `PASS` |
| **TC-CLICK-02** | Multi-Point Sequence | Overlay aktif, mode Multi-Point. | 1. Tekan tombol `+` 3 kali (Pin 1, 2, 3 muncul).<br>2. Posisikan ke 3 tombol berbeda.<br>3. Tekan tombol Play. | Ketukan dieksekusi berurutan: Pin 1 $\to$ Pin 2 $\to$ Pin 3 berulang secara presisi. | `PASS` |
| **TC-CLICK-03** | Dynamic Target Removal | Mode Multi-Point dengan 3 pin di layar. | 1. Tekan tombol `-` pada dock. | Pin nomor 3 terhapus dari layar, menyisakan Pin 1 dan 2. Urutan eksekusi disesuaikan. | `PASS` |
| **TC-DOCK-01** | Dragging Floating Dock | Floating dock tampil di layar. | 1. Tekan dan tahan drag handle dock.<br>2. Geser ke tepi kiri/kanan layar. | Dock berpindah posisi dengan mulus tanpa memicu tombol Play/Pause secara tidak sengaja. | `PASS` |
| **TC-DOCK-02** | Minimize to Bubble | Dock dalam posisi expanded. | 1. Tekan tombol Minimize (`<`). | Dock menyusut menjadi bubble kecil ($36\times36\text{ dp}$) di pinggir layar. Mengetuk bubble mengembalikannya ke dock penuh. | `PASS` |
| **TC-PROF-01** | Save Profile Preset | Konfigurasi 2 target pin telah diset. | 1. Buka Quick Settings.<br>2. Pilih "Simpan Profil".<br>3. Beri nama "Farming Event".<br>4. Simpan. | Profil tersimpan ke database lokal (Hive). Slot tersimpan menjadi (1/5). | `PASS` |
| **TC-PROF-02** | Max Profile Slot Limit | Telah tersimpan 5 profil di database. | 1. Coba simpan profil baru ke-6. | Muncul toast alert: "Batas maksimal 5 profil telah tercapai. Hapus salah satu profil lama." | `PASS` |
| **TC-PROF-03** | Load Profile Preset | Profil "Farming Event" tersedia di daftar. | 1. Buka Profile Manager di Flutter.<br>2. Pilih "Farming Event".<br>3. Ketuk "Gunakan Profil". | Floating dock terbuka dan pin 1 & 2 otomatis muncul pada koordinat $(X, Y)$ tersimpan. | `PASS` |

---

## 2. Stress Test Protocol (10.000 Ketukan Berturut-turut)

### 2.1 Tujuan & Kriteria Kelulusan
Menguji ketahanan `KlikinAccessibilityService` dan engine coroutine saat mengeksekusi beban kerja tinggi secara kontinu tanpa intervensi pengguna.
* **Kriteria Kelulusan (Pass Criteria):**
  - Berhasil mengeksekusi minimal **10.000 ketukan** tanpa jeda macet.
  - Zero crash (`FATAL EXCEPTION`).
  - Zero Application Not Responding (`ANR`).
  - Alokasi RAM tidak mengalami memory leakage yang menanjak konstan (*flat memory curve*).

### 2.2 Setup Lingkungan Pengujian
1. Hubungkan perangkat uji Android via USB dengan mode **USB Debugging** aktif.
2. Aktifkan penunjuk visual sentuhan Android untuk memverifikasi ketukan nyata:
   ```bash
   adb shell settings put system show_touches 1
   adb shell settings put system pointer_location 1
   ```

### 2.3 Perintah Terminal Monitoring & Eksekusi
Jalankan filter logcat khusus di terminal komputer untuk memantau siklus loop dan mendeteksi anomali:

```bash
# Terminal 1: Monitor log loop dan error execution
adb logcat -c && adb logcat -v time -s "KlikinAccessibilityService:V" "GestureDispatcherEngine:V" "AndroidRuntime:E" "ActivityManager:E"
```

Untuk mensimulasikan beban kerja di atas aplikasi target berat, jalankan stressor background pada perangkat via ADB:
```bash
# Terminal 2 (Opsional): Simulasikan background CPU stress di device Android
adb shell "while true; do :; done &"
```

Atur Klikin:
* Mode: **Multi-Point** (2 Target Pin).
* Delay: **$100\text{ ms}$** per target.
* Loop Count: **5.000 siklus** ($5.000 \times 2 = 10.000\text{ ketukan}$).
* Tekan **Play**.

---

## 3. Memory & Resource Profiling Protocol (< 60 MB RAM)

### 3.1 Spesifikasi Ambang Batas
Total alokasi memori **Proportional Set Size (PSS)** aplikasi Klikin saat background service dan floating overlay aktif di atas game/aplikasi lain **wajib berada di bawah $60\text{ MB}$** ($< 60.000\text{ KB}$).

### 3.2 Perintah Inspeksi Memori Manual via ADB
Jalankan perintah berikut untuk menginspeksi alokasi memori real-time:

```bash
adb shell dumpsys meminfo com.klikin.app
```

Perhatikan baris **TOTAL PSS**:
```
                   Pss      Pss   Shared  Private   Shared  Private     Heap     Heap     Heap
                 Total    Clean    Clean    Clean    Dirty    Dirty     Size    Alloc     Free
                ------   ------   ------   ------   ------   ------   ------   ------   ------
  Native Heap    18240        0        0    18120     1240      120    36864    24120    12743
  Dalvik Heap     8450        0        0     8320     1890       80    14200     7980     6220
        Stack      980        0        0      980        0        0
       .so mmap     4120     1200     8200      400     4100      120
      TOTAL PSS: 42150 KB  <--- HARUS DI BAWAH 60.000 KB (PASS)
```

### 3.3 Skrip Otomasi Monitoring RAM (PowerShell)
Simpan dan jalankan skrip loop ini di terminal untuk memonitor stabilitas RAM selama stress test:

```powershell
# Monitor RAM setiap 5 detik selama pengujian
Write-Host "Memulai monitoring RAM Klikin (Limit: 60 MB)..." -ForegroundColor Cyan
while ($true) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $dump = adb shell dumpsys meminfo com.klikin.app
    $pssLine = $dump | Select-String "TOTAL PSS:"
    
    if ($pssLine) {
        $pssKb = [regex]::Match($pssLine.Line, "(\d+)").Groups[1].Value
        $pssMb = [math]::Round([int]$pssKb / 1024, 2)
        
        if ($pssMb -gt 60.0) {
            Write-Host "[$timestamp] ALERT: RAM melebihi ambang batas! -> $pssMb MB" -ForegroundColor Red
        } else {
            Write-Host "[$timestamp] NORMAL: RAM aman -> $pssMb MB (PSS: $pssKb KB)" -ForegroundColor Green
        }
    } else {
        Write-Host "[$timestamp] Menunggu proses com.klikin.app..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 5
}
```

---

## 4. Edge Case Testing Scenarios

### 4.1 Pengujian Rotasi Layar (Portrait $\leftrightarrow$ Landscape)
Pengguna game sering memutar perangkat secara horizontal.
* **Prosedur Uji:**
  1. Pasang Pin 1 di koordinat portrait $(X=900, Y=1800)$.
  2. Paksa rotasi layar ke mode landscape menggunakan ADB:
     ```bash
     # Putar ke Landscape (Rotasi 90 derajat)
     adb shell settings put system user_rotation 1
     ```
  3. Amati perilaku pin target.
* **Hasil yang Diharapkan:** Pin target tidak menghilang di luar layar. Utilitas `CoordinateSanitizer` otomatis menggeser pin ke dalam batas layar horizontal aktif ($16\text{ dp}$ dari tepi).
* **Kembalikan ke Portrait:**
  ```bash
  adb shell settings put system user_rotation 0
  ```

---

### 4.2 Pengujian Emergency Hardware Killswitch (Volume Down)
Menguji apakah interupsi tombol fisik mampu menghentikan klik otomatis liar seketika.
* **Prosedur Uji:**
  1. Jalankan loop klik dengan interval cepat ($25\text{ ms}$) dalam mode Infinite.
  2. Lepaskan jari dari layar (jangan sentuh panel).
  3. Kirimkan event tombol fisik **Volume Down** via ADB:
     ```bash
     adb shell input keyevent 25
     ```
* **Hasil yang Diharapkan:**
  - Loop ketukan berhenti seketika dalam waktu $< 100\text{ ms}$.
  - State dock berubah menjadi `PAUSED`.
  - Volume media ponsel tidak berkurang (karena event dikonsumsi oleh `onKeyEvent`).

---

### 4.3 Pengujian Layar Mati (Screen Lock / Display Off)
Mencegah klik otomatis berjalan di atas lockscreen ponsel.
* **Prosedur Uji:**
  1. Jalankan auto-clicker.
  2. Matikan layar ponsel via tombol power:
     ```bash
     adb shell input keyevent 26
     ```
  3. Nyalakan kembali layar ponsel dan periksa logcat.
* **Hasil yang Diharapkan:** Broadcast receiver `Intent.ACTION_SCREEN_OFF` langsung membatalkan coroutine loop dan menonaktifkan touch injection saat layar mati.

---

### 4.4 Penanganan OEM Aggressive Battery Killer (MIUI, ColorOS, OneUI)
Vendor Android tertentu (Xiaomi, Oppo, Vivo, Samsung) secara agresif mematikan background service untuk menghemat baterai.
* **Langkah Validasi Whitelist:**
  1. Masukkan Klikin ke dalam whitelist penghemat baterai sistem:
     ```bash
     adb shell dumpsys deviceidle whitelist +com.klikin.app
     ```
  2. Uji simulasi Doze Mode saat layar mati:
     ```bash
     # Paksa Android masuk ke status Doze Mode dalam
     adb shell dumpsys battery unplug
     adb shell dumpsys deviceidle step deep
     ```
  3. Verifikasi apakah `OverlayControllerService` tetap bertahan dan icon persistent notification tetap ada di status bar.
