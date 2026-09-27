package com.klikin.app

import androidx.annotation.NonNull
import com.klikin.app.bridge.NativeMethodHandler
import com.klikin.app.bridge.NativeStreamHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val controllerChannel = "com.klikin.app/controller"
    private val eventsChannel = "com.klikin.app/events"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Registrasi MethodChannel: Flutter -> Android Native
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controllerChannel)
            .setMethodCallHandler(NativeMethodHandler(this))

        // Registrasi EventChannel: Android Native -> Flutter Event Stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventsChannel)
            .setStreamHandler(NativeStreamHandler)
    }
}
