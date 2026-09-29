package com.klikin.app.engine

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.util.Log
import com.klikin.app.model.NativeLoopConfig
import com.klikin.app.model.NativeTargetPoint
import kotlinx.coroutines.*
import kotlin.coroutines.resume

class GestureDispatcherEngine(
    private val serviceProvider: () -> AccessibilityService?,
    private val sanitizer: CoordinateSanitizer
) {
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var executionJob: Job? = null

    @Volatile
    var isRunning: Boolean = false
        private set

    @Volatile
    var isPaused: Boolean = false
        private set

    @Volatile
    private var currentTargets: List<NativeTargetPoint> = emptyList()

    val isExecuting: Boolean
        get() = isRunning && !isPaused

    var onStateChanged: ((state: String, message: String?) -> Unit)? = null
    var onProgress: ((currentLoop: Int, totalLoops: Int, targetIndex: Int) -> Unit)? = null
    var dockBoundsProvider: (() -> Rect?)? = null

    fun updateTargets(targets: List<NativeTargetPoint>) {
        currentTargets = targets.map { sanitizer.sanitize(it) }
    }

    fun start(targets: List<NativeTargetPoint>, loopConfig: NativeLoopConfig) {
        if (targets.isEmpty()) {
            onStateChanged?.invoke("ERROR", "No target points configured for execution")
            return
        }

        stop() // Cancel any ongoing loop cleanly

        updateTargets(targets)
        isRunning = true
        isPaused = false
        onStateChanged?.invoke("RUNNING", null)

        executionJob = scope.launch {
            var completedLoops = 0
            val startTimeMs = System.currentTimeMillis()

            try {
                while (isActive && isRunning) {
                    if (isPaused) {
                        delay(100L)
                        continue
                    }

                    val targetsToExecute = currentTargets
                    for (target in targetsToExecute) {
                        if (!isActive || !isRunning) break
                        while (isPaused && isRunning) {
                            delay(100L)
                        }
                        if (!isActive || !isRunning) break

                        // Ambil koordinat target terbaru jika pin digeser saat paused
                        val activeTarget = currentTargets.find { it.index == target.index } ?: target

                        onProgress?.invoke(completedLoops + 1, loopConfig.maxCount ?: 0, activeTarget.index)

                        // Verifikasi Safety Exclusion Zone: cegah klik di atas area Floating Dock
                        val dockBounds = dockBoundsProvider?.invoke()
                        if (dockBounds != null && CoordinateSanitizer.isOverlappingControlDock(
                                activeTarget.x.toFloat(),
                                activeTarget.y.toFloat(),
                                dockBounds
                            )
                        ) {
                            Log.w(TAG, "Target #${activeTarget.index} at (${activeTarget.x}, ${activeTarget.y}) is inside Floating Dock safety zone. Skipping tap to prevent UI loop.")
                        } else {
                            // Injeksi ketukan via Android AccessibilityService
                            val success = dispatchTap(activeTarget.x.toFloat(), activeTarget.y.toFloat(), activeTarget.pressDurationMs)
                            if (!success && isRunning) {
                                Log.w(TAG, "OS rejected gesture dispatch at (${activeTarget.x}, ${activeTarget.y})")
                            }
                        }

                        // Jeda waktu antar ketukan (Wajib minimum 25ms per AGENTS.md)
                        delay(activeTarget.delayAfterMs.coerceAtLeast(25L))
                    }

                    completedLoops++
                    val elapsedMinutes = (System.currentTimeMillis() - startTimeMs) / 60000.0

                    if (loopConfig.isFinished(completedLoops, elapsedMinutes)) {
                        break
                    }
                }
            } catch (e: CancellationException) {
                // Coroutine dibatalkan secara normal
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error in gesture execution loop", e)
                onStateChanged?.invoke("ERROR", e.localizedMessage)
            } finally {
                isRunning = false
                isPaused = false
                onStateChanged?.invoke("IDLE", null)
            }
        }
    }

    suspend fun dispatchTap(x: Float, y: Float, durationMs: Long): Boolean {
        val service = serviceProvider() ?: return false
        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0, durationMs.coerceAtLeast(20L))
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        return suspendCancellableCoroutine { continuation ->
            val callback = object : AccessibilityService.GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    if (continuation.isActive) continuation.resume(true)
                }

                override fun onCancelled(gestureDescription: GestureDescription?) {
                    if (continuation.isActive) continuation.resume(false)
                }
            }

            val dispatched = service.dispatchGesture(gesture, callback, null)
            if (!dispatched && continuation.isActive) {
                continuation.resume(false)
            }
        }
    }

    fun pause() {
        if (isRunning && !isPaused) {
            isPaused = true
            onStateChanged?.invoke("PAUSED", null)
        }
    }

    fun resume() {
        if (isRunning && isPaused) {
            isPaused = false
            onStateChanged?.invoke("RUNNING", null)
        }
    }

    fun stop() {
        isRunning = false
        isPaused = false
        executionJob?.cancel()
        executionJob = null
        onStateChanged?.invoke("IDLE", null)
    }

    fun emergencyStop(reason: String) {
        isRunning = false
        isPaused = false
        executionJob?.cancel()
        executionJob = null
        onStateChanged?.invoke("EMERGENCY_STOP", reason)
        com.klikin.app.bridge.NativeStreamHandler.emitEmergencyStop(reason)
    }

    fun destroy() {
        stop()
        scope.cancel()
    }

    companion object {
        private const val TAG = "GestureDispatcherEngine"
    }
}
