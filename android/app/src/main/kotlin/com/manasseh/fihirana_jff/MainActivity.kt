package com.manasseh.fihirana_jff

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Extends the audio_service launcher activity, not FlutterActivity: the manifest
// must launch the audio activity, so a plain FlutterActivity is never created
// and the channel below would silently never register.
class MainActivity : AudioServiceActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.manasseh.fihirana_jff/power"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> result.success(isUnrestricted())
                "canScheduleExactAlarms" -> result.success(allowsExactAlarms())
                "areNotificationsEnabled" -> result.success(areNotificationsEnabled())
                "openBatteryOptimizationSettings" -> result.success(openBatterySettings())
                else -> result.notImplemented()
            }
        }
    }

    // Asked of the system rather than of the notification plugin: the plugin
    // answers "allowed" before its channels are registered, which would hide a
    // real block behind an initialisation detail.
    private fun areNotificationsEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return true
        val manager = getSystemService(android.app.NotificationManager::class.java)
            ?: return true
        return manager.areNotificationsEnabled()
    }

    // A device already in Doze's whitelist, or a build without PowerManager:
    // both read as unrestricted so the app stops asking.
    private fun isUnrestricted(): Boolean {
        val power = getSystemService(PowerManager::class.java) ?: return true
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    // Android 12 revoked exact alarms by default, so a daily verse lands whenever
    // Doze next wakes the app instead of at the minute the user chose.
    private fun allowsExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarms = getSystemService(android.app.AlarmManager::class.java) ?: return true
        return alarms.canScheduleExactAlarms()
    }

    // The system list screen rather than ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS:
    // the user flips the switch, so no auto-granted exemption is claimed.
    private fun openBatterySettings(): Boolean {
        return try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            true
        } catch (notFound: ActivityNotFoundException) {
            openAppDetails()
        }
    }

    private fun openAppDetails(): Boolean {
        return try {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName")
                )
            )
            true
        } catch (stillNotFound: ActivityNotFoundException) {
            false
        }
    }
}
