package com.klikin.app.overlay

import android.content.Context
import android.graphics.Point
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import com.klikin.app.engine.CoordinateSanitizer
import com.klikin.app.model.NativeTargetPoint

class FloatingWindowManager(
    private val context: Context,
    private val sanitizer: CoordinateSanitizer
) {
    private val windowManager: WindowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val mainHandler = Handler(Looper.getMainLooper())

    var dockView: FloatingDockView? = null
        private set

    val targetPins: MutableList<TargetPinView> = mutableListOf()

    var onTargetsChangedListener: ((List<NativeTargetPoint>) -> Unit)? = null
    var onPlayPauseToggleListener: (() -> Unit)? = null
    var onSettingsClickListener: (() -> Unit)? = null
    var onCloseClickListener: (() -> Unit)? = null

    val isDockAttached: Boolean
        get() = dockView != null

    fun showDock() {
        if (dockView != null) return

        mainHandler.post {
            val dock = FloatingDockView(context, windowManager, object : FloatingDockView.Listener {
                override fun onTogglePlayPause() {
                    onPlayPauseToggleListener?.invoke()
                }

                override fun onOpenSettings() {
                    onSettingsClickListener?.invoke()
                }

                override fun onClose() {
                    onCloseClickListener?.invoke()
                }
            })

            try {
                windowManager.addView(dock.expandedView, dock.expandedParams)
                dockView = dock
            } catch (e: Exception) {
                // WindowManager.BadTokenException guard
            }
        }
    }

    fun addTarget(x: Int, y: Int): NativeTargetPoint {
        val nextIndex = targetPins.size + 1
        val rawPoint = NativeTargetPoint(index = nextIndex, x = x, y = y)
        val point = sanitizer.sanitize(rawPoint)

        mainHandler.post {
            val pin = TargetPinView(context, windowManager, point) { updatedPoint ->
                notifyTargetsChanged()
            }

            try {
                windowManager.addView(pin.view, pin.layoutParams)
                targetPins.add(pin)
                notifyTargetsChanged()
            } catch (e: Exception) {
                // Ignore if detached
            }
        }
        return point
    }

    fun removeLastTarget() {
        if (targetPins.isEmpty()) return

        mainHandler.post {
            val lastPin = targetPins.removeAt(targetPins.size - 1)
            try {
                windowManager.removeView(lastPin.view)
            } catch (e: Exception) {
                // Ignore
            }
            notifyTargetsChanged()
        }
    }

    fun syncTargets(newTargets: List<NativeTargetPoint>) {
        mainHandler.post {
            // Remove existing pins
            targetPins.forEach { pin ->
                try {
                    windowManager.removeView(pin.view)
                } catch (e: Exception) {
                    // Ignore
                }
            }
            targetPins.clear()

            // Add new pins (Sanitasi batas koordinat & waktu sebelum attach ke WindowManager)
            newTargets.map { sanitizer.sanitize(it) }.forEach { sanitizedTarget ->
                val pin = TargetPinView(context, windowManager, sanitizedTarget) {
                    notifyTargetsChanged()
                }
                try {
                    windowManager.addView(pin.view, pin.layoutParams)
                    targetPins.add(pin)
                } catch (e: Exception) {
                    // Ignore
                }
            }
            notifyTargetsChanged()
        }
    }

    fun getDockBounds(): Rect? {
        val dock = dockView ?: return null
        val targetView = if (dock.isMinimized) dock.minimizedView else dock.expandedView
        if (!targetView.isAttachedToWindow) return null
        val loc = IntArray(2)
        targetView.getLocationOnScreen(loc)
        val density = context.resources.displayMetrics.density
        val defaultWidth = ((if (dock.isMinimized) 56f else 60f) * density).toInt()
        val defaultHeight = ((if (dock.isMinimized) 56f else 260f) * density).toInt()
        val width = targetView.width.takeIf { it > 0 } ?: defaultWidth
        val height = targetView.height.takeIf { it > 0 } ?: defaultHeight
        return Rect(loc[0], loc[1], loc[0] + width, loc[1] + height)
    }

    fun setExecutionState(isExecuting: Boolean) {
        mainHandler.post {
            dockView?.updateExecutionState(isExecuting)

            // Dynamic touch flag: Saat RUNNING, aktifkan FLAG_NOT_TOUCHABLE pada semua pin
            targetPins.forEach { pin ->
                pin.setTouchPassthrough(isExecuting)
            }
        }
    }

    fun getTargets(): List<NativeTargetPoint> {
        return targetPins.map { it.targetPoint }
    }

    private fun notifyTargetsChanged() {
        val currentTargets = getTargets()
        onTargetsChangedListener?.invoke(currentTargets)
    }

    fun destroy() {
        mainHandler.post {
            // Remove all target pins
            targetPins.forEach { pin ->
                try {
                    windowManager.removeView(pin.view)
                } catch (e: Exception) {
                    // Ignore
                }
            }
            targetPins.clear()

            // Remove dock view
            dockView?.let { dock ->
                try {
                    if (dock.isMinimized) {
                        windowManager.removeView(dock.minimizedView)
                    } else {
                        windowManager.removeView(dock.expandedView)
                    }
                } catch (e: Exception) {
                    // Ignore
                }
            }
            dockView = null
        }
    }
}
