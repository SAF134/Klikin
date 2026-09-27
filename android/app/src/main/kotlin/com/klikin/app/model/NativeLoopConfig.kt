package com.klikin.app.model

enum class LoopType {
    INFINITE,
    FINITE_COUNT,
    TIMER
}

data class NativeLoopConfig(
    val loopType: LoopType = LoopType.INFINITE,
    val maxCount: Int? = null,
    val durationMinutes: Int? = null
) {
    fun isFinished(completedLoops: Int, elapsedMinutes: Double = 0.0): Boolean {
        return when (loopType) {
            LoopType.INFINITE -> false
            LoopType.FINITE_COUNT -> maxCount != null && completedLoops >= maxCount
            LoopType.TIMER -> durationMinutes != null && elapsedMinutes >= durationMinutes
        }
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): NativeLoopConfig {
            val typeStr = (map["loopType"] as? String) ?: "INFINITE"
            val loopType = try {
                LoopType.valueOf(typeStr)
            } catch (e: Exception) {
                LoopType.INFINITE
            }
            val maxCount = (map["maxCount"] as? Number)?.toInt()
            val durationMinutes = (map["durationMinutes"] as? Number)?.toInt()
            return NativeLoopConfig(
                loopType = loopType,
                maxCount = maxCount,
                durationMinutes = durationMinutes
            )
        }
    }
}
