package com.klikin.app.bridge

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object NativeStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    fun emitStateChanged(state: String, message: String? = null) {
        emit(mapOf(
            "eventType" to "STATE_CHANGED",
            "state" to state,
            "message" to message
        ))
    }

    fun emitTargetCoordinatesChanged(index: Int, x: Int, y: Int) {
        emit(mapOf(
            "eventType" to "TARGET_COORDINATES_CHANGED",
            "index" to index,
            "x" to x,
            "y" to y
        ))
    }

    fun emitProgress(currentLoop: Int, totalLoops: Int, targetIndex: Int) {
        emit(mapOf(
            "eventType" to "EXECUTION_PROGRESS",
            "currentLoop" to currentLoop,
            "totalLoops" to totalLoops,
            "targetIndex" to targetIndex
        ))
    }

    fun emitEmergencyStop(reason: String) {
        emit(mapOf(
            "eventType" to "EMERGENCY_STOP",
            "reason" to reason
        ))
    }
}
