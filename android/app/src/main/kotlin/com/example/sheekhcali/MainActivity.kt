package com.example.sheekhcali

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// audio_service needs its shared FlutterEngine for background playback.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Android 13+ needs POST_NOTIFICATIONS at runtime for the playback
        // notification (lock-screen and shade controls). Asked once, when the
        // user first plays a lesson; playback works without it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sheekhcalinuur/permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT >= 33 &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7001)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
