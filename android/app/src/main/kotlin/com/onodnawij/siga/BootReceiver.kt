package com.onodnawij.siga

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent?.action == null) return

        val handler = Handler(Looper.getMainLooper())

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                handler.postDelayed({
                    logAndSend(context, "BootReceiver", "Device rebooted. Restarting services...")
                    startHeheService(context)
                    toggleNotificationListenerService(context)
                    WatchdogScheduler.schedule(context)
                    logAndSend(context, "BootReceiver", "Boot complete signal processed and services restarted.")
                }, 5_000L) // 15 seconds delay
            }

            "com.onodnawij.siga.RESTART_HEHESERVICE" -> {
                logAndSend(context, "BootReceiver", "Manual restart request: HeheService.")
                startHeheService(context)
            }

            "com.onodnawij.siga.RESTART_NOTIFICATIONSERVICE" -> {
                logAndSend(context, "BootReceiver", "Manual restart request: NotificationService.")
                toggleNotificationListenerService(context)
            }
        }
    }

    private fun startHeheService(context: Context) {
        val intent = Intent(context, HeheService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
        logAndSend(context, "BootReceiver", "Requested start for HeheService.")
    }

    private fun toggleNotificationListenerService(context: Context) {
        val componentName = ComponentName(context, NotificationService::class.java)
        val pm = context.packageManager

        pm.setComponentEnabledSetting(
            componentName,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
        pm.setComponentEnabledSetting(
            componentName,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )

        logAndSend(context, "BootReceiver", "Toggled NotificationService to rebind it.")
    }

    private fun logAndSend(context: Context, tag: String, message: String) {
        val logMessage = "Boot: $message"
        Log.d("Siga.$tag", logMessage)

        val inputData = Data.Builder()
            .putString("logEntry", logMessage)
            .build()

        val workRequest = OneTimeWorkRequestBuilder<TelegramWorker>()
            .setInputData(inputData)
            .build()

        WorkManager.getInstance(context.applicationContext).enqueue(workRequest)
    }
}
