package com.klikin.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.klikin.app.MainActivity
import com.klikin.app.bridge.NativeStreamHandler
import com.klikin.app.engine.CoordinateSanitizer
import com.klikin.app.model.NativeLoopConfig
import com.klikin.app.overlay.FloatingWindowManager

class OverlayControllerService : Service() {

    lateinit var windowManager: FloatingWindowManager
        private set

    private var loopConfig: NativeLoopConfig = NativeLoopConfig()

    override fun onCreate() {
        super.onCreate()
        instance = this
        val sanitizer = CoordinateSanitizer(this)
        windowManager = FloatingWindowManager(this, sanitizer)

        setupDockListeners()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_SERVICE -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START_OVERLAY -> {
                startForeground(NOTIFICATION_ID, buildNotification())
                windowManager.showDock()
                NativeStreamHandler.emitStateChanged("ARMED", "Overlay dock started")
            }
        }
        return START_STICKY
    }

    private fun setupDockListeners() {
        windowManager.onPlayPauseToggleListener = {
            toggleExecution()
        }

        windowManager.onTargetsChangedListener = { targets ->
            for (t in targets) {
                NativeStreamHandler.emitTargetCoordinatesChanged(t.index, t.x, t.y)
            }
        }

        windowManager.onCloseClickListener = {
            stopSelf()
        }
    }

    fun toggleExecution() {
        val accService = KlikinAccessibilityService.instance
        if (accService == null) {
            // Accessibility service belum aktif di Settings
            NativeStreamHandler.emitStateChanged("ERROR", "Accessibility Service not connected")
            return
        }

        val gestureEngine = accService.gestureEngine
        if (gestureEngine.isExecuting) {
            gestureEngine.pause()
            windowManager.setExecutionState(false)
            NativeStreamHandler.emitStateChanged("PAUSED", null)
        } else if (gestureEngine.isPaused) {
            gestureEngine.resume()
            windowManager.setExecutionState(true)
            NativeStreamHandler.emitStateChanged("RUNNING", null)
        } else {
            val targets = windowManager.getTargets()
            if (targets.isNotEmpty()) {
                gestureEngine.onStateChanged = { state, msg ->
                    val isRunning = (state == "RUNNING")
                    windowManager.setExecutionState(isRunning)
                    NativeStreamHandler.emitStateChanged(state, msg)
                }
                gestureEngine.onProgress = { current, total, targetIndex ->
                    NativeStreamHandler.emitProgress(current, total, targetIndex)
                }
                gestureEngine.start(targets, loopConfig)
                windowManager.setExecutionState(true)
                NativeStreamHandler.emitStateChanged("RUNNING", null)
            }
        }
    }

    fun updateLoopConfig(config: NativeLoopConfig) {
        this.loopConfig = config
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Klikin Background Controller",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifikasi status panel kontrol melayang Klikin"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val stopIntent = Intent(this, OverlayControllerService::class.java).apply {
            action = ACTION_STOP_SERVICE
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Klikin Auto-Clicker")
            .setContentText("Panel kontrol sedang aktif di latar belakang")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(openPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Hentikan", stopPendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        KlikinAccessibilityService.instance?.gestureEngine?.stop()
        windowManager.destroy()
        if (instance == this) {
            instance = null
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val CHANNEL_ID = "klikin_overlay_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START_OVERLAY = "com.klikin.app.ACTION_START_OVERLAY"
        const val ACTION_STOP_SERVICE = "com.klikin.app.ACTION_STOP_SERVICE"

        @Volatile
        var instance: OverlayControllerService? = null
            private set

        val isRunning: Boolean
            get() = instance != null

        fun start(context: Context) {
            val intent = Intent(context, OverlayControllerService::class.java).apply {
                action = ACTION_START_OVERLAY
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, OverlayControllerService::class.java).apply {
                action = ACTION_STOP_SERVICE
            }
            context.startService(intent)
        }
    }
}
