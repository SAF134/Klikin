package com.klikin.app.model

data class NativeTargetPoint(
    val index: Int,
    val x: Int,
    val y: Int,
    val pressDurationMs: Long = 50L,
    val delayAfterMs: Long = 500L
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "index" to index,
            "x" to x,
            "y" to y,
            "pressDurationMs" to pressDurationMs,
            "delayAfterMs" to delayAfterMs
        )
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): NativeTargetPoint {
            val index = (map["index"] as? Number)?.toInt() ?: 1
            val x = (map["x"] as? Number)?.toInt() ?: 0
            val y = (map["y"] as? Number)?.toInt() ?: 0
            val pressDurationMs = (map["pressDurationMs"] as? Number)?.toLong() ?: 50L
            val delayAfterMs = (map["delayAfterMs"] as? Number)?.toLong() ?: 500L
            return NativeTargetPoint(
                index = index,
                x = x,
                y = y,
                pressDurationMs = pressDurationMs,
                delayAfterMs = delayAfterMs
            )
        }
    }
}
