package com.onodnawij.siga

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.widget.Toast
import android.content.ComponentName
import androidx.work.Data
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "siga_automator/channel"
    private val STORAGE_PERMISSION_CODE = 1001 // Request Code for Storage Permission
    private var resultPending: MethodChannel.Result? = null
    private var waitingForAccessibilityResult = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WatchdogScheduler.schedule(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    val isEnabled = isAccessibilityServiceEnabled()
                    result.success(isEnabled)
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings(result)
                }
                "checkStoragePermission" -> {
                    val isGranted = checkStoragePermission()
                    result.success(isGranted)
                }
                "requestStoragePermission" -> {
                    requestStoragePermission()
                    result.success(null)
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponent = ComponentName(this, HeheService::class.java)
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.contains(expectedComponent.flattenToString())
    }

    private fun openAccessibilitySettings(result: MethodChannel.Result) {
        resultPending = result
        waitingForAccessibilityResult = true

        val logEntry = "Requesting Accessibility"
        triggerTelegramWorker(logEntry)

        val brand = Build.BRAND.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        var intent: Intent? = null

        try {
            intent = when {
                manufacturer.contains("xiaomi") || brand.contains("xiaomi") -> {
                    Intent("com.miui.accessibility").apply {
                        setPackage("com.miui.securitycenter")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                manufacturer.contains("samsung") || brand.contains("samsung") -> {
                    Intent().apply {
                        setClassName("com.android.settings", "com.android.settings.Settings\$AccessibilitySettingsActivity")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                manufacturer.contains("huawei") || brand.contains("huawei") -> {
                    Intent().apply {
                        component = ComponentName("com.android.settings", "com.android.settings.accessibility.AccessibilitySettings")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                manufacturer.contains("oppo") || brand.contains("realme") -> {
                    Intent().apply {
                        component = ComponentName("com.coloros.oppoguardelf", "com.coloros.privacypermissionsentry.PermissionTopActivity")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                manufacturer.contains("vivo") -> {
                    Intent().apply {
                        component = ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
                else -> {
                    Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        putExtra(":settings:fragment_args_key", "com.onodnawij.siga/.HeheService")
                        setPackage("com.android.settings")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                }
            }

            startActivity(intent)
        } catch (e: Exception) {

            // Fallback to standard intent
            try {
                val fallbackIntent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
            } catch (ex: Exception) {
                result.error("ERROR", "Unable to open accessibility settings", ex.localizedMessage)
            }
        }
    }


    override fun onResume() {
        super.onResume()
        if (waitingForAccessibilityResult && resultPending != null) {
            val isEnabled = isAccessibilityServiceEnabled()
            resultPending?.success(isEnabled)
            resultPending = null
            waitingForAccessibilityResult = false
        }
    }


    private fun isNotificationServiceEnabled(): Boolean {
        val enabledServices = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        val colonSplitter = enabledServices?.split(":") ?: return false
        return colonSplitter.any { it.contains(packageName, ignoreCase = true) }
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun checkStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            true // Scoped Storage
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStoragePermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), STORAGE_PERMISSION_CODE)
        }
    }

    private fun triggerTelegramWorker(logEntry: String) {
        val inputData = Data.Builder()
            .putString("logEntry", logEntry)
            .build()

        val request = OneTimeWorkRequest.Builder(TelegramWorker::class.java)
            .setInputData(inputData)
            .build()

        WorkManager.getInstance(applicationContext).enqueue(request)
    }
}
