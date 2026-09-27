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

    val layoutParams: WindowManager.LayoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        },
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.START
        x = targetPoint.x - 48 // Center pin over target
        y = targetPoint.y - 48
    }

    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var initialWindowX = 0
    private var initialWindowY = 0
    private var isDragging = false

    init {
        tvIndex.text = targetPoint.index.toString()
        setupTouchListener()
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

                    if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
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
                        // Hitung koordinat tengah fisik pin (center of 48dp)
                        val centerX = layoutParams.x + 48
                        val centerY = layoutParams.y + 48
                        targetPoint = targetPoint.copy(x = centerX, y = centerY)
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
