package com.klikin.app.engine

import android.content.Context
import android.graphics.Point
import android.graphics.Rect
import android.os.Build
import android.view.WindowManager
import com.klikin.app.model.NativeTargetPoint

class CoordinateSanitizer(private val context: Context) {

    fun getScreenDimensions(): Point {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val point = Point()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics = wm.currentWindowMetrics
            val insets = metrics.windowInsets.getInsetsIgnoringVisibility(
                android.view.WindowInsets.Type.systemBars()
            )
            val bounds = metrics.bounds
            point.x = bounds.width()
            point.y = bounds.height()
        } else {
            @Suppress("DEPRECATION")
            wm.defaultDisplay.getRealSize(point)
        }
        return point
    }

    fun sanitize(target: NativeTargetPoint): NativeTargetPoint {
        val screen = getScreenDimensions()

        // Clamp coordinates within active display boundary
        val safeX = target.x.coerceIn(0, screen.x)
        val safeY = target.y.coerceIn(0, screen.y)

        // Strict timing constraints per Golden Rules & SECURITY.md
        val safeDuration = target.pressDurationMs.coerceIn(20L, 5000L)
        val safeDelay = target.delayAfterMs.coerceIn(25L, 300_000L) // Anti-freeze: Min 25ms

        return target.copy(
            x = safeX,
            y = safeY,
            pressDurationMs = safeDuration,
            delayAfterMs = safeDelay
        )
    }

    companion object {
        fun isOverlappingControlDock(targetX: Float, targetY: Float, dockBounds: Rect): Boolean {
            return dockBounds.contains(targetX.toInt(), targetY.toInt())
        }
    }
}
