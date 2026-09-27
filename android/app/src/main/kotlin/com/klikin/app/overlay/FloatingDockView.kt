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

@SuppressLint("ClickableViewAccessibility")
class FloatingDockView(
    private val context: Context,
    private val windowManager: WindowManager,
    private val listener: Listener
) {
    interface Listener {
        fun onTogglePlayPause()
        fun onAddTarget()
        fun onRemoveTarget()
        fun onOpenSettings()
        fun onClose()
    }

    // Expanded View
    val expandedView: View = LayoutInflater.from(context).inflate(R.layout.view_floating_dock, null)
    private val dragHandle: View = expandedView.findViewById(R.id.dock_drag_handle)
    private val btnPlayPause: FrameLayout = expandedView.findViewById(R.id.btn_play_pause)
    private val btnPlayPauseBg: View = expandedView.findViewById(R.id.btn_play_pause_bg)
    private val btnPlayPauseIcon: TextView = expandedView.findViewById(R.id.btn_play_pause_icon)
    private val btnAddTarget: FrameLayout = expandedView.findViewById(R.id.btn_add_target)
    private val btnRemoveTarget: FrameLayout = expandedView.findViewById(R.id.btn_remove_target)
    private val btnSettings: FrameLayout = expandedView.findViewById(R.id.btn_settings)
    private val btnMinimize: FrameLayout = expandedView.findViewById(R.id.btn_minimize)
    private val btnClose: FrameLayout = expandedView.findViewById(R.id.btn_close)

    // Minimized Bubble View
    val minimizedView: View = LayoutInflater.from(context).inflate(R.layout.view_floating_dock_min, null)

    var isMinimized: Boolean = false
        private set

    val expandedParams: WindowManager.LayoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        },
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.START
        x = 24
        y = 300
    }

    val minimizedParams: WindowManager.LayoutParams = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        },
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.START
        x = 16
        y = 300
    }

    init {
        setupDragListener(dragHandle, expandedParams, expandedView)
        setupDragListener(minimizedView, minimizedParams, minimizedView)

        btnPlayPause.setOnClickListener { listener.onTogglePlayPause() }
        btnAddTarget.setOnClickListener { listener.onAddTarget() }
        btnRemoveTarget.setOnClickListener { listener.onRemoveTarget() }
        btnSettings.setOnClickListener { listener.onOpenSettings() }
        btnClose.setOnClickListener { listener.onClose() }

        btnMinimize.setOnClickListener { minimize() }
        minimizedView.setOnClickListener { expand() }
    }

    private fun setupDragListener(touchTarget: View, params: WindowManager.LayoutParams, targetView: View) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isClick = false

        touchTarget.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isClick = true
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()

                    if (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10) {
                        isClick = false
                    }

                    params.x = initialX + deltaX
                    params.y = initialY + deltaY

                    try {
                        windowManager.updateViewLayout(targetView, params)
                    } catch (e: Exception) {
                        // View might be detached
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (isClick && targetView == minimizedView) {
                        expand()
                    }
                    true
                }
                else -> false
            }
        }
    }

    fun minimize() {
        if (!isMinimized) {
            isMinimized = true
            minimizedParams.x = expandedParams.x
            minimizedParams.y = expandedParams.y
            try {
                windowManager.removeView(expandedView)
                windowManager.addView(minimizedView, minimizedParams)
            } catch (e: Exception) {
                // Handle safe attach/detach
            }
        }
    }

    fun expand() {
        if (isMinimized) {
            isMinimized = false
            expandedParams.x = minimizedParams.x
            expandedParams.y = minimizedParams.y
            try {
                windowManager.removeView(minimizedView)
                windowManager.addView(expandedView, expandedParams)
            } catch (e: Exception) {
                // Handle safe attach/detach
            }
        }
    }

    fun updateExecutionState(isExecuting: Boolean) {
        if (isExecuting) {
            btnPlayPauseBg.setBackgroundResource(R.drawable.bg_btn_pause)
            btnPlayPauseIcon.text = "❚❚"
        } else {
            btnPlayPauseBg.setBackgroundResource(R.drawable.bg_btn_play)
            btnPlayPauseIcon.text = "▶"
        }
    }
}
