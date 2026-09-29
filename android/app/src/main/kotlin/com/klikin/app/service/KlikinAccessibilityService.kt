package com.klikin.app.service

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import com.klikin.app.engine.CoordinateSanitizer
import com.klikin.app.engine.GestureDispatcherEngine

class KlikinAccessibilityService : AccessibilityService() {

    lateinit var sanitizer: CoordinateSanitizer
        private set

    lateinit var gestureEngine: GestureDispatcherEngine
        private set

    private var screenOffReceiver: BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        sanitizer = CoordinateSanitizer(this)
        gestureEngine = GestureDispatcherEngine({ instance }, sanitizer)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        registerScreenOffReceiver()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // canRetrieveWindowContent="false", Klikin tidak membaca konten layar demi privasi
    }

    override fun onInterrupt() {
        gestureEngine.stop()
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        // Hardware Killswitch: Tekan Volume Down seketika membatalkan loop ketukan aktif
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN && event.action == KeyEvent.ACTION_DOWN) {
            if (gestureEngine.isExecuting) {
                gestureEngine.emergencyStop("Hardware Volume Down Key Pressed")
                return true // Konsumsi event agar volume media ponsel tidak berkurang
            }
        }
        return super.onKeyEvent(event)
    }

    private fun registerScreenOffReceiver() {
        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        screenOffReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                    if (gestureEngine.isExecuting) {
                        gestureEngine.emergencyStop("Screen Turned Off (ACTION_SCREEN_OFF)")
                    }
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOffReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenOffReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        gestureEngine.destroy()
        screenOffReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // Abaikan jika receiver sudah di-unregister
            }
        }
        screenOffReceiver = null
        if (instance == this) {
            instance = null
        }
    }

    companion object {
        @Volatile
        var instance: KlikinAccessibilityService? = null
            private set

        val isConnected: Boolean
            get() = instance != null
    }
}
