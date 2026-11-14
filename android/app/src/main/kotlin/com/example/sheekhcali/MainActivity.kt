package com.example.sheekhcali

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

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
        // Testing builds carry the original recording as an APK asset
        // (android/app/build.gradle.kts, SHEEKH_TESTING_AUDIO). The player
        // needs a file, so it is copied once into app-private storage:
        // hashed while copying, written to a temporary name, flushed to disk,
        // then renamed into place only if its SHA-256 and size are the
        // original's. Dart re-verifies the result before playing it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sheekhcalinuur/bundled_media")
            .setMethodCallHandler { call, result ->
                if (call.method != "unpack") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val asset = call.argument<String>("asset")!!
                val dest = File(call.argument<String>("dest")!!)
                val sha256 = call.argument<String>("sha256")!!
                val bytes = (call.argument<Number>("bytes")!!).toLong()
                val main = Handler(Looper.getMainLooper())
                unpacker.execute {
                    val outcome = unpack(asset, dest, sha256, bytes)
                    main.post { result.success(outcome) }
                }
            }
    }

    private val unpacker = Executors.newSingleThreadExecutor()

    private fun unpack(asset: String, dest: File, sha256: String, bytes: Long): Map<String, String> {
        val part = File(dest.path + ".part")
        try {
            dest.parentFile?.mkdirs()
            val free = dest.parentFile?.usableSpace ?: 0L
            if (free < bytes + 4L * 1024 * 1024) {
                return mapOf("status" to "nospace", "detail" to "$free bytes free")
            }
            val stream = try {
                assets.open(asset)
            } catch (e: FileNotFoundException) {
                // Not a testing build (or packed without the recording).
                return mapOf("status" to "missing", "detail" to asset)
            }
            val digest = MessageDigest.getInstance("SHA-256")
            var copied = 0L
            stream.use { input ->
                FileOutputStream(part).use { output ->
                    val buffer = ByteArray(1 shl 16)
                    while (true) {
                        val n = input.read(buffer)
                        if (n < 0) break
                        digest.update(buffer, 0, n)
                        output.write(buffer, 0, n)
                        copied += n
                    }
                    output.flush()
                    output.fd.sync()
                }
            }
            val actual = digest.digest().joinToString("") { "%02x".format(it) }
            if (copied != bytes || actual != sha256) {
                part.delete()
                return mapOf("status" to "mismatch", "detail" to actual)
            }
            if (!part.renameTo(dest)) {
                part.delete()
                return mapOf("status" to "error", "detail" to "rename failed")
            }
            return mapOf("status" to "ok", "detail" to actual)
        } catch (e: Exception) {
            part.delete()
            return mapOf("status" to "error", "detail" to (e.message ?: e.javaClass.simpleName))
        }
    }
}
