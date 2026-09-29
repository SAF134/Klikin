# ==============================================================================
# ProGuard & R8 Configuration Rules — Klikin Android Auto-Clicker
# ==============================================================================

# 1. Privacy & Log Stripping (SECURITY.md Section 2.2)
# Melucuti seluruh pemanggilan log sistem Android agar koordinat (X, Y) tidak bocor ke logcat
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# 2. Flutter Engine and Core Plugins Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 3. Klikin Native Architecture Components & Platform Channels
-keep class com.klikin.app.MainActivity { *; }
-keep class com.klikin.app.bridge.** { *; }
-keep class com.klikin.app.model.** { *; }
-keep class com.klikin.app.service.** { *; }
-keep class com.klikin.app.overlay.** { *; }
-keep class com.klikin.app.engine.** { *; }

# Pertahankan member method & konstruktor model data untuk serialisasi Map
-keepclassmembers class com.klikin.app.model.** { *; }

# 4. Suppress warnings for optional Play Core deferred components
-dontwarn com.google.android.play.core.**
