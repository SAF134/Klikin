package com.klikin.app.overlay

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import com.klikin.app.R
import com.klikin.app.model.NativeTargetPoint
import kotlin.math.abs
import kotlin.math.roundToInt

@SuppressLint("ClickableViewAccessibility")
class TargetPinView(
    private val context: Context,
    private val windowManager: WindowManager,
    var targetPoint: NativeTargetPoint,
    private val onCoordinatesChanged: (NativeTargetPoint) -> Unit
) {
    val view: View = LayoutInflater.from(context).inflate(R.layout.view_target_pin, null)
    private val pinBadge: FrameLayout = view.findViewById(R.id.target_pin_badge)
    private val tvIndex: TextView = view.findViewById(R.id.tv_target_index)

    // Perhitungan dimensi fisik dinamis berbasis densitas layar (DP ke Pixel: 56dp)
    private val density: Float = context.resources.displayMetrics.density
    val pinSizePx: Int = (56f * density).roundToInt()
    val pinRadiusPx: Int = pinSizePx / 2

    val layoutParams: WindowManager.LayoutParams = WindowManager.LayoutParams(
        pinSizePx,
        pinSizePx,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        },
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.START
        x = targetPoint.x - pinRadiusPx
        y = targetPoint.y - pinRadiusPx
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var initialWindowX = 0
    private var initialWindowY = 0
    private var isDragging = false

    init {
        tvIndex.text = targetPoint.index.toString()
        setupTouchListener()

        // Kalibrasi presisi koordinat fisik layar begitu view selesai di-layout WindowManager
        view.post {
            calibrateExactCoordinates()
        }
    }

    private fun calibrateExactCoordinates() {
        val loc = IntArray(2)
        view.getLocationOnScreen(loc)
        if (loc[0] != 0 || loc[1] != 0) {
            val exactCenterX = loc[0] + pinRadiusPx
            val exactCenterY = loc[1] + pinRadiusPx
            if (abs(exactCenterX - targetPoint.x) > 2 || abs(exactCenterY - targetPoint.y) > 2) {
                targetPoint = targetPoint.copy(x = exactCenterX, y = exactCenterY)
                onCoordinatesChanged(targetPoint)
            }
        }
    }

    private fun setupTouchListener() {
        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    initialWindowX = layoutParams.x
                    initialWindowY = layoutParams.y
                    isDragging = false
                    pinBadge.setBackgroundResource(R.drawable.bg_target_pin_focus)
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()

                    if (abs(deltaX) > 5 || abs(deltaY) > 5) {
                        isDragging = true
                    }

                    layoutParams.x = initialWindowX + deltaX
                    layoutParams.y = initialWindowY + deltaY

                    try {
                        windowManager.updateViewLayout(view, layoutParams)
                    } catch (e: Exception) {
                        // View may be detached
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    pinBadge.setBackgroundResource(R.drawable.bg_target_pin)
                    if (isDragging) {
                        // Hitung koordinat fisik absolut layar (True Physical Screen Pixels)
                        val loc = IntArray(2)
                        view.getLocationOnScreen(loc)
                        val exactCenterX = if (loc[0] != 0 || loc[1] != 0) {
                            loc[0] + pinRadiusPx
                        } else {
                            layoutParams.x + pinRadiusPx
                        }
                        val exactCenterY = if (loc[0] != 0 || loc[1] != 0) {
                            loc[1] + pinRadiusPx
                        } else {
                            layoutParams.y + pinRadiusPx
                        }

                        targetPoint = targetPoint.copy(x = exactCenterX, y = exactCenterY)
                        onCoordinatesChanged(targetPoint)
                    }
                    true
                }
                else -> false
            }
        }
    }

    fun updateIndex(newIndex: Int) {
        targetPoint = targetPoint.copy(index = newIndex)
        tvIndex.text = newIndex.toString()
    }

    fun setTouchPassthrough(enabled: Boolean) {
        if (enabled) {
            // Mode Running: FLAG_NOT_TOUCHABLE aktif agar klik tembus ke game di bawahnya
            layoutParams.flags = layoutParams.flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
        } else {
            // Mode Paused/Idle: Matikan FLAG_NOT_TOUCHABLE agar pin bisa digeser pengguna
            layoutParams.flags = layoutParams.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv()
        }

        try {
            windowManager.updateViewLayout(view, layoutParams)
        } catch (e: Exception) {
            // View may not be attached
        }
    }
}
