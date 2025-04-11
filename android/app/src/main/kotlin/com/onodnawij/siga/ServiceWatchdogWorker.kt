package com.onodnawij.siga

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

class ServiceWatchdogWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    override fun doWork(): Result {
        val heheRunning = isServiceRunning(HeheService::class.java)
        val notifRunning = isServiceRunning(NotificationService::class.java)

        val heheStatus = if (heheRunning) "✅" else "❌"
        val notifStatus = if (notifRunning) "✅" else "❌"

        if (!heheRunning) startService(HeheService::class.java)
        if (!notifRunning) toggleNotificationListener()

        val fixNeeded = !heheRunning || !notifRunning
        val logMessage = buildString {
            appendLine("Watchdog:")
            appendLine(" - Hehe  : $heheStatus")
            appendLine(" - Notif : $notifStatus")
            if (fixNeeded) append("Fixing it...")
        }

        logAndSendTelegram(logMessage)
        return Result.success()
    }

    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return manager.getRunningServices(Int.MAX_VALUE).any {
            it.service.className == serviceClass.name
        }
    }

    private fun startService(serviceClass: Class<*>) {
        val intent = Intent(context, serviceClass)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun toggleNotificationListener() {
        try {
            val componentName = ComponentName(context, NotificationService::class.java)
            val pm = context.packageManager

            pm.setComponentEnabledSetting(
                componentName,
                android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                android.content.pm.PackageManager.DONT_KILL_APP
            )
            Thread.sleep(500)
            pm.setComponentEnabledSetting(
                componentName,
                android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                android.content.pm.PackageManager.DONT_KILL_APP
            )
            Log.d("Siga.Watchdog", "Notification listener toggled")
        } catch (e: Exception) {
            Log.e("Siga.Watchdog", "Toggle error: ${e.message}")
        }
    }

    private fun logAndSendTelegram(message: String) {
        Log.d("Siga.Watchdog", message)

        val inputData = Data.Builder()
            .putString("logEntry", message)
            .build()

        val request = OneTimeWorkRequestBuilder<TelegramWorker>()
            .setInputData(inputData)
            .build()

        WorkManager.getInstance(context.applicationContext).enqueue(request)
    }
}
