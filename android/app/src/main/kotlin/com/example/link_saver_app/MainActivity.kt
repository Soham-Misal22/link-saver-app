package com.example.link_saver_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "share_receiver"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedText" -> {
                    val sharedText = getSharedText()
                    result.success(sharedText)
                }
                "clearSharedText" -> {
                    clearSharedText()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Intent handling moved to ShareReceiverActivity
    // MainActivity only needs to provide data via MethodChannel

    private fun getSharedText(): String? {
        return getSharedPreferences("shared_data", MODE_PRIVATE)
            .getString("shared_text", null)
    }



    private fun clearSharedText() {
        getSharedPreferences("shared_data", MODE_PRIVATE)
            .edit()
            .remove("shared_text")
            .apply()
    }
}