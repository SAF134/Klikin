# Security Policy & Implementation Guide (SECURITY.md) — Klikin

* **Aplikasi:** Klikin (Android Auto-Clicker & Automation)
* **Target OS:** Android 7.0+ (API Level 24+)
* **Klasifikasi Peran:** Senior Application Security Engineer (Android AppSec)
* **Dokumen Versi:** 1.0.0
* **Status:** Mandatori & Non-Negotiable untuk Tim Engineering

---

## 1. Android IPC & Intent Protection (Anti-Confused Deputy)

### 1.1 Vektor Serangan & Ancaman
Aplikasi auto-clicker memiliki hak istimewa tinggi (`AccessibilityService.dispatchGesture`). Jika komponen service atau receiver diekspor secara publik (`android:exported="true"`), aplikasi berbahaya (malware) pihak ketiga tanpa izin aksesibilitas dapat mengirimkan Intent tersembunyi ke Klikin untuk mengeksekusi ketukan sembarang (seperti menekan tombol "Transfer Uang" pada aplikasi perbankan atau "Izinkan" pada dialog perizinan sistem). Serangan ini diklasifikasikan sebagai **Confused Deputy Attack**.

### 1.2 Deklarasi Wajib di `AndroidManifest.xml`
Seluruh service dan receiver internal **wajib berstatus private**, dan `KlikinAccessibilityService` dikunci secara eksklusif hanya untuk sistem Android (`system_server`):

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.klikin.app">

    <!-- Izin Tingkat Sistem -->
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:label="Klikin"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"> <!-- Cegah pencurian profil via adb backup -->

        <!-- 1. Accessibility Service Engine: Wajib Dikunci dengan Izin Sistem -->
        <service
            android:name=".service.KlikinAccessibilityService"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="false">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>

        <!-- 2. Foreground Controller Service: Mutlak Private -->
        <service
            android:name=".service.OverlayControllerService"
            android:exported="false"
            android:foregroundServiceType="specialUse" />

    </application>
</manifest>
```

### 1.3 Validasi Caller Identity pada Kotlin Layer
Jika terdapat komunikasi antar-komponen via broadcast internal, gunakan `LocalBroadcastManager` atau validasi identitas Caller UID secara ketat:

```kotlin
// service/OverlayControllerService.kt
private fun validateInternalCaller(): Boolean {
    val callerUid = Binder.getCallingUid()
    val myUid = android.os.Process.myUid()
    if (callerUid != myUid) {
        throw SecurityException("Unauthorized IPC access: Caller UID $callerUid does not match application UID $myUid")
    }
    return true
}
```

---

## 2. Privacy & Screen Data Leakage Prevention

### 2.1 Konfigurasi Ketat `accessibility_service_config.xml`
Secara default, `AccessibilityService` dapat membaca seluruh teks pada layar pengguna (termasuk password, OTP, dan pesan chat). Klikin **hanya membutuhkan injeksi gestur koordinat $(X, Y)$, bukan pembacaan data layar**. 

Konfigurasi berikut wajib diterapkan untuk menjamin privasi pengguna 100%:

```xml
<!-- android/app/src/main/res/xml/accessibility_service_config.xml -->
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:description="@string/accessibility_service_description"
    android:accessibilityEventTypes="typeAllMask"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault|flagRequestFilterKeyEvents"
    android:canPerformGestures="true"
    android:canRetrieveWindowContent="false"       <!-- KRITIS: Larang pembacaan konten layar -->
    android:canRequestFilterKeyEvents="true"        <!-- Diperlukan untuk Hardware Killswitch -->
    android:notificationTimeout="100" />
```

### 2.2 Kebijakan Pembersihan Log (ProGuard / R8 Stripping)
Untuk mencegah kebocoran koordinat atau status sensitif ke `logcat` Android (yang dapat dibaca melalui debugging USB), seluruh pemanggilan `android.util.Log` wajib dilucuti pada release build:

```groovy
// android/app/proguard-rules.pro
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}
```

---

## 3. Denial of Service & Screen Lockout Prevention

### 3.1 Vektor Ancaman
Jika eksekusi klik otomatis berjalan dalam interval cepat ($25\text{ ms}$) dan pengguna tidak dapat menjangkau tombol pause (misalnya panel melayang tertutup dialog pihak ketiga atau terklik oleh gesturnya sendiri), antrean sentuhan buatan akan membanjiri `InputDispatcher` sistem. Jari fisik pengguna tidak dapat merespons, mengakibatkan **Permanent Touch Lockout**.

### 3.2 Implementasi Hardware Emergency Killswitch
Sistem wajib memantau penekanan tombol fisik **Volume Down** untuk membatalkan loop gestur seketika tanpa memerlukan respons sentuhan layar:

```kotlin
// service/KlikinAccessibilityService.kt
class KlikinAccessibilityService : AccessibilityService() {

    private var gestureJob: Job? = null
    var isExecuting: Boolean = false

    override fun onKeyEvent(event: KeyEvent): Boolean {
        // Deteksi tombol Volume Down ditekan
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN && event.action == KeyEvent.ACTION_DOWN) {
            if (isExecuting) {
                triggerEmergencyKillswitch("Hardware Volume Down Pressed")
                return true // Konsumsi event agar tidak mengecilkan volume media game
            }
        }
        return super.onKeyEvent(event)
    }

    fun triggerEmergencyKillswitch(reason: String) {
        gestureJob?.cancel() // Batalkan coroutine loop seketika
        isExecuting = false
        
        // Broadcast status ke Flutter dan Overlay View
        NativeStreamHandler.emitEmergencyStop(reason)
        FloatingWindowManager.updateExecutionState(isExecuting = false)
    }
}
```

### 3.3 Safety Exclusion Zone (Proteksi Bounding Box Dock)
Injeksi sentuhan otomatis dilarang keras dilakukan di atas area fisik panel kendali (*Floating Dock*). Sebelum `dispatchGesture` dipanggil, koordinat wajib diverifikasi:

```kotlin
// engine/CoordinateSanitizer.kt
object CoordinateSanitizer {
    fun isOverlappingControlDock(targetX: Float, targetY: Float, dockBounds: Rect): Boolean {
        return dockBounds.contains(targetX.toInt(), targetY.toInt())
    }
}
```
*Jika target pin berada di dalam bounding box dock, sistem wajib menolak eksekusi titik tersebut atau dock otomatis bergeser ke tepi berlawanan secara preventif.*

---

## 4. Input Boundary Validation & Data Sanitizer

Model data yang diterima dari penyimpanan lokal maupun platform channel harus divalidasi dan di-*clamp* secara ketat untuk mencegah `IllegalArgumentException` pada Android Graphics Framework.

### 4.1 Boundary Rules Matrix

| Parameter | Tipe | Batas Bawah (Minimum) | Batas Atas (Maksimum) | Tindakan jika Pelanggaran |
| :--- | :--- | :--- | :--- | :--- |
| `x` | `Int` | `0 px` | `DisplayMetrics.widthPixels` | Clamping ke batas layar terdekat. |
| `y` | `Int` | `0 px` | `DisplayMetrics.heightPixels` | Clamping ke batas layar terdekat. |
| `pressDurationMs` | `Long` | `20 ms` | `5000 ms` | Clamping ke $50\text{ ms}$ (default). |
| `delayAfterMs` | `Long` | `25 ms` (Strict Limit) | `300,000 ms` (5 menit) | Clamping ke $25\text{ ms}$ jika $< 25\text{ ms}$. |
| `maxCount` | `Int` | `1` | `1,000,000` | Tolak jika $\le 0$ pada mode `FINITE_COUNT`. |

### 4.2 Sanitizer Implementation (Kotlin Native)

```kotlin
// engine/CoordinateSanitizer.kt
package com.klikin.app.engine

import android.content.Context
import android.graphics.Point
import android.view.WindowManager
import com.klikin.app.model.NativeTargetPoint

class CoordinateSanitizer(private val context: Context) {

    fun getScreenDimensions(): Point {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val point = Point()
        wm.defaultDisplay.getRealSize(point)
        return point
    }

    fun sanitize(target: NativeTargetPoint): NativeTargetPoint {
        val screen = getScreenDimensions()

        val clampedX = target.x.coerceIn(0, screen.x)
        val clampedY = target.y.coerceIn(0, screen.y)
        val clampedDuration = target.pressDurationMs.coerceIn(20L, 5000L)
        val clampedDelay = target.delayAfterMs.coerceIn(25L, 300_000L) // Anti-freeze clamp

        return target.copy(
            x = clampedX,
            y = clampedY,
            pressDurationMs = clampedDuration,
            delayAfterMs = clampedDelay
        )
    }
}
```

---

## 5. Local Storage Security & Data Isolation

### 5.1 Sandbox Storage Enforcement
1. **Dilarang Menggunakan External Storage:** Dilarang menyimpan profil atau file konfigurasi di direktori publik `/sdcard/` atau `Environment.getExternalStorageDirectory()`. Seluruh data wajib berada di dalam direktori privat aplikasi:
   ```
   /data/data/com.klikin.app/app_flutter/
   ```
2. **Kunci SharedPreferences:** Jika SharedPreferences digunakan, wajib beroperasi dalam mode `Context.MODE_PRIVATE` (nilai default). Mode `MODE_WORLD_READABLE` dan `MODE_WORLD_WRITEABLE` dilarang keras.

### 5.2 Hive Box Encryption via Android Keystore
Untuk mencegah modifikasi file database profil oleh aplikasi lain pada perangkat yang di-root, Hive Box dienkripsi menggunakan kunci AES-256 yang disimpan di Android Keystore via `flutter_secure_storage`:

```dart
// lib/data/datasources/secure_storage_helper.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key_v1';

  static Future<HiveAesCipher> getEncryptionCipher() async {
    String? base64Key = await _storage.read(key: _keyName);
    
    if (base64Key == null) {
      // Buat 256-bit key baru jika belum ada
      final newKey = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64Url.encode(newKey));
      return HiveAesCipher(newKey);
    }
    
    final keyBytes = base64Url.decode(base64Key);
    return HiveAesCipher(keyBytes);
  }
}
```

---

## 6. Audit & Verification Checklist for Engineering

Sebelum kode masuk ke tahap rilis (*Production/Release Build*), tim pengembang wajib memvalidasi checklist berikut:

- [ ] `android:exported="false"` terpasang pada seluruh Service & Receiver di `AndroidManifest.xml`.
- [ ] `android:canRetrieveWindowContent="false"` terverifikasi aktif di `accessibility_service_config.xml`.
- [ ] Hardware Killswitch (Volume Down) terbukti mampu menghentikan loop ketukan dalam waktu $< 100\text{ ms}$.
- [ ] Batas minimal interval $25\text{ ms}$ terkunci di level UI Flutter dan level Native Kotlin.
- [ ] ProGuard/R8 rules terpasang untuk melucuti seluruh `android.util.Log` pada release APK.
- [ ] Seluruh data profil tersimpan murni di `Context.MODE_PRIVATE` dalam app sandbox.
