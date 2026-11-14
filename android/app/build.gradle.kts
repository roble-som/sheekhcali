import java.security.MessageDigest
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---- Testing-only recording (C-26 as extended on 2026-11-13) -----------------
// Only when the Dart define SHEEKH_TESTING_AUDIO=true is passed
// (tool/build_testing_apk.sh). The original R3 file is verified by SHA-256 and
// copied byte for byte into an Android asset, stored uncompressed. Without the
// define, nothing is packed and the build is the ordinary one.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { encoded ->
            runCatching { String(Base64.getDecoder().decode(encoded)) }.getOrNull()
        }
        ?.mapNotNull { entry ->
            val i = entry.indexOf('=')
            if (i > 0) entry.substring(0, i) to entry.substring(i + 1) else null
        }
        ?.toMap()
        ?: emptyMap()
val bundleTestingAudio = dartDefines["SHEEKH_TESTING_AUDIO"] == "true"
val r3Sha256 = "3300e3644ff3631414ffab463d4c34c2ee88da162b77564dd661a187f7b0834f"
val r3Bytes = 12587299L
val testingAudioDir = layout.buildDirectory.dir("generated/testing_audio").get().asFile

fun sha256Of(file: File): String {
    val digest = MessageDigest.getInstance("SHA-256")
    file.inputStream().use { input ->
        val buffer = ByteArray(1 shl 16)
        while (true) {
            val n = input.read(buffer)
            if (n < 0) break
            digest.update(buffer, 0, n)
        }
    }
    return digest.digest().joinToString("") { "%02x".format(it) }
}

if (bundleTestingAudio) {
    val source = rootProject.projectDir.parentFile.resolve("shiiq_mp3/003-الفاتحة 1-آخرها.mp3")
    if (!source.isFile) {
        throw GradleException("SHEEKH_TESTING_AUDIO: the original recording is missing at $source")
    }
    val actual = sha256Of(source)
    if (source.length() != r3Bytes || actual != r3Sha256) {
        throw GradleException("SHEEKH_TESTING_AUDIO: $source is not the original R3 (sha256 $actual)")
    }
    val staged = testingAudioDir.resolve("testing-audio/$r3Sha256.mp3")
    if (!staged.isFile || sha256Of(staged) != r3Sha256) {
        staged.parentFile.mkdirs()
        source.copyTo(staged, overwrite = true)
        if (sha256Of(staged) != r3Sha256) {
            throw GradleException("SHEEKH_TESTING_AUDIO: the staged copy does not match")
        }
    }
    logger.lifecycle("SHEEKH_TESTING_AUDIO: packing the original R3 ($r3Sha256) for a testing build")
} else {
    // An earlier testing build must not leak into this one.
    testingAudioDir.deleteRecursively()
}

android {
    namespace = "com.example.sheekhcali"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sheekhcali"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Recordings are played and hash-checked as stored: never compressed.
    androidResources {
        noCompress += "mp3"
    }

    if (bundleTestingAudio) {
        sourceSets.getByName("main").assets.srcDir(testingAudioDir)
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
