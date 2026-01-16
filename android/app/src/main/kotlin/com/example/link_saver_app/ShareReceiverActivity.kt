package com.example.link_saver_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle

class ShareReceiverActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (intent?.action == Intent.ACTION_SEND) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
            val combined = listOfNotNull(subject, text).joinToString(" ").trim()

            if (combined.isNotEmpty()) {
                getSharedPreferences("shared_data", MODE_PRIVATE)
                    .edit()
                    .putString("shared_text", combined)
                    .commit()
            }
        }

        val launch = Intent(this, MainActivity::class.java)
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(launch)
        finish()
    }
}
