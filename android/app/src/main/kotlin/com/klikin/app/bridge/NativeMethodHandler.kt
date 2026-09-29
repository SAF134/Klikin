package com.klikin.app.bridge

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.klikin.app.model.NativeLoopConfig
import com.klikin.app.model.NativeTargetPoint
import com.klikin.app.service.KlikinAccessibilityService
import com.klikin.app.service.OverlayControllerService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeMethodHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermissions" -> {
                val hasOverlay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Settings.canDrawOverlays(context)
                } else {
                    true
                }
                val hasAccessibility = isAccessibilityServiceEnabled()
                result.success(
                    mapOf(
                        "hasOverlayPermission" to hasOverlay,
                        "hasAccessibilityPermission" to hasAccessibility
                    )
                )
            }

            "requestOverlayPermission" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${context.packageName}")
                        ).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                } catch (e: Exception) {
                    result.error("ERR_INTENT_FAILED", "Failed to launch overlay settings", e.message)
                }
            }

            "requestAccessibilityPermission" -> {
                try {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERR_INTENT_FAILED", "Failed to launch accessibility settings", e.message)
                }
            }

            "startOverlay" -> {
                val hasOverlay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Settings.canDrawOverlays(context)
                } else {
                    true
                }
                if (!hasOverlay) {
                    result.error("ERR_NO_PERMISSION", "Overlay permission not granted", null)
                    return
                }

                val targetsRaw = call.argument<List<Map<String, Any?>>>("targets")
                val loopConfigRaw = call.argument<Map<String, Any?>>("loopConfig")

                val targets = targetsRaw?.map { NativeTargetPoint.fromMap(it) }
                val loopConfig = loopConfigRaw?.let { NativeLoopConfig.fromMap(it) }

                OverlayControllerService.start(context, targets, loopConfig)
                result.success(true)
            }

            "stopOverlay" -> {
                OverlayControllerService.stop(context)
                result.success(true)
            }

            "syncTargets" -> {
                val targetsRaw = call.arguments as? List<Map<String, Any?>>
                if (targetsRaw != null) {
                    val targets = targetsRaw.map { NativeTargetPoint.fromMap(it) }
                    OverlayControllerService.setPendingTargets(targets)
                    result.success(true)
                } else {
                    result.error("ERR_INVALID_COORDS", "Invalid targets payload", null)
                }
            }

            "updateLoopConfig" -> {
                val configRaw = call.arguments as? Map<String, Any?>
                if (configRaw != null) {
                    val loopConfig = NativeLoopConfig.fromMap(configRaw)
                    OverlayControllerService.setPendingLoopConfig(loopConfig)
                    result.success(true)
                } else {
                    result.error("ERR_INVALID_CONFIG", "Invalid loop config payload", null)
                }
            }

            "startExecution" -> {
                val service = OverlayControllerService.instance
                if (service != null) {
                    val acc = KlikinAccessibilityService.instance
                    if (acc != null) {
                        service.toggleExecution()
                        result.success(true)
                    } else {
                        result.error("ERR_SERVICE_DEAD", "Accessibility Service is not bound", null)
                    }
                } else {
                    result.error("ERR_NOT_READY", "Overlay Controller is not active", null)
                }
            }

            "pauseExecution" -> {
                val acc = KlikinAccessibilityService.instance
                if (acc != null) {
                    acc.gestureEngine.pause()
                    OverlayControllerService.instance?.windowManager?.setExecutionState(false)
                    result.success(true)
                } else {
                    result.success(false)
                }
            }

            "getServiceStatus" -> {
                val acc = KlikinAccessibilityService.instance
                val status = when {
                    acc?.gestureEngine?.isRunning == true && acc.gestureEngine.isPaused -> "PAUSED"
                    acc?.gestureEngine?.isRunning == true -> "RUNNING"
                    OverlayControllerService.instance?.windowManager?.targetPins?.isNotEmpty() == true -> "ARMED"
                    else -> "IDLE"
                }
                result.success(status)
            }

            else -> result.notImplemented()
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        if (KlikinAccessibilityService.isConnected) return true

        val serviceName = "${context.packageName}/${KlikinAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.contains(serviceName) || enabledServices.contains(context.packageName)
    }
}
