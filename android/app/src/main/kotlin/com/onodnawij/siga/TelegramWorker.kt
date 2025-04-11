package com.onodnawij.siga

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.io.IOException

class TelegramWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {

    private val telegramBotToken = BuildConfig.TELEGRAM_BOT_TOKEN
    private val telegramChatId = BuildConfig.TELEGRAM_CHAT_ID

    override fun doWork(): Result {
        val manufacturer = Build.MANUFACTURER
        val model = Build.MODEL
        val deviceName = "$manufacturer $model"

        val filePath = inputData.getString("filePath")
        val logEntry = inputData.getString("logEntry")
        val client = OkHttpClient()

        return try {
            if (!filePath.isNullOrEmpty()) {
                val file = File(filePath)
                if (file.exists()) {
                    val success = sendTelegramFile(client, file, "[$deviceName] $logEntry")
                    if (success) {
                        file.delete()
                        Log.d("Siga.TelegramWorker", "Deleted file after upload: ${file.name}")
                    }
                } else {
                    val errMsg = "[$deviceName]\n❌ File not found: $filePath"
                    sendTelegramMessage(client, errMsg)
                }
            } else if (!logEntry.isNullOrEmpty()) {
                val message = "[$deviceName]\n$logEntry"
                sendTelegramMessage(client, message)
            } else {
                val errMsg = "[$deviceName]\n⚠️ TelegramWorker received no input."
                sendTelegramMessage(client, errMsg)
            }

            Result.success()
        } catch (e: Exception) {
            val errorReport = "[$deviceName]\n❗ TelegramWorker error:\n${e.message}"
            runCatching { sendTelegramMessage(client, errorReport) }
            Log.e("Siga.TelegramWorker", "Error in TelegramWorker", e)
            Result.success()
        }
    }

    private fun sendTelegramMessage(client: OkHttpClient, message: String) {
        val url = "https://api.telegram.org/bot$telegramBotToken/sendMessage"
        val formBody = FormBody.Builder()
            .add("chat_id", telegramChatId)
            .add("text", message)
            .build()

        val request = Request.Builder()
            .url(url)
            .post(formBody)
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                Log.e("Siga.TelegramWorker", "sendMessage failed: ${response.code} ${response.message}")
            }
        }
    }

    private fun sendTelegramFile(client: OkHttpClient, file: File, caption: String? = null): Boolean {
        val url = "https://api.telegram.org/bot$telegramBotToken/sendDocument"

        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("chat_id", telegramChatId)
            .addFormDataPart("document", file.name, file.asRequestBody("application/octet-stream".toMediaType()))
            .apply {
                if (!caption.isNullOrEmpty()) {
                    addFormDataPart("caption", caption)
                }
            }
            .build()

        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .build()

        client.newCall(request).execute().use { response ->
            return if (response.isSuccessful) {
                true
            } else {
                val fallbackMsg = "❌ Failed to upload file '${file.name}': ${response.code} ${response.message}"
                sendTelegramMessage(client, fallbackMsg)
                false
            }
        }
    }
}
