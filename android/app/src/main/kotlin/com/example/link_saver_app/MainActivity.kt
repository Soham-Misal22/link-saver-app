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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
            val sharedSubject = intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: ""
            
            // Combine subject and text to ensure we catch the URL wherever it is
            val combined = "$sharedSubject $sharedText".trim()
            
            if (combined.isNotEmpty()) {
                println("Link Saver Native: Received shared text: $combined")

                // Store the shared text
                setSharedText(combined)
            }
        }
    }

    private fun getSharedText(): String? {
        return getSharedPreferences("shared_data", MODE_PRIVATE)
            .getString("shared_text", null)
    }

    private fun setSharedText(text: String) {
        getSharedPreferences("shared_data", MODE_PRIVATE)
            .edit()
            .putString("shared_text", text)
            .apply()
            
        // Push to Flutter if engine is ready
        methodChannel?.invokeMethod("onSharedTextReceived", text)
    }

    private fun clearSharedText() {
        getSharedPreferences("shared_data", MODE_PRIVATE)
            .edit()
            .remove("shared_text")
            .apply()
    }
}