package com.klikin.app.engine

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
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

    val isExecuting: Boolean
        get() = isRunning && !isPaused

    var onStateChanged: ((state: String, message: String?) -> Unit)? = null
    var onProgress: ((currentLoop: Int, totalLoops: Int, targetIndex: Int) -> Unit)? = null

    fun start(targets: List<NativeTargetPoint>, loopConfig: NativeLoopConfig) {
        if (targets.isEmpty()) {
            onStateChanged?.invoke("ERROR", "No target points configured for execution")
            return
        }

        stop() // Cancel any ongoing loop cleanly

        isRunning = true
        isPaused = false
        onStateChanged?.invoke("RUNNING", null)

        executionJob = scope.launch {
            val sanitizedTargets = targets.map { sanitizer.sanitize(it) }
            var completedLoops = 0
            val startTimeMs = System.currentTimeMillis()

            try {
                while (isActive && isRunning) {
                    if (isPaused) {
                        delay(100L)
                        continue
                    }

                    for (target in sanitizedTargets) {
                        if (!isActive || !isRunning) break
                        while (isPaused && isRunning) {
                            delay(100L)
                        }

                        onProgress?.invoke(completedLoops + 1, loopConfig.maxCount ?: 0, target.index)

                        // Injeksi ketukan via Android AccessibilityService
                        val success = dispatchTap(target.x.toFloat(), target.y.toFloat(), target.pressDurationMs)
                        if (!success && isRunning) {
                            Log.w(TAG, "OS rejected gesture dispatch at (${target.x}, ${target.y})")
                        }

                        // Jeda waktu antar ketukan (Wajib minimum 25ms per AGENTS.md)
                        delay(target.delayAfterMs.coerceAtLeast(25L))
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
