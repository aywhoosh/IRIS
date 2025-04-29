package com.example.iris_flutter_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.content.Context
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class SettingsMethodChannel(private val context: Context) {
    
    private val CHANNEL = "com.example.iris_flutter_app/settings"
    
    fun configureChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "disableImpeller" -> {
                    disableImpeller()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun disableImpeller() {
        // Set system properties to disable hardware acceleration for problematic operations
        System.setProperty("flutter.disableImpeller", "true")
        
        // Additional settings to reduce GPU pressure
        if (context is FlutterActivity) {
            try {
                // Set low render priority to reduce GPU load
                val activity = context as FlutterActivity
                activity.runOnUiThread {
                    activity.window.setFlags(
                        WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                        WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
                    )
                }
            } catch (e: Exception) {
                // Log exception but continue
                e.printStackTrace()
            }
        }
    }
}
