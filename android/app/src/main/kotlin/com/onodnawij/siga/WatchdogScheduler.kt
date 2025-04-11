package com.onodnawij.siga

import android.content.Context
import androidx.work.*
import java.util.concurrent.TimeUnit

object WatchdogScheduler {
    fun schedule(context: Context) {
        val constraints = Constraints.Builder()
            .setRequiresBatteryNotLow(false)
            .setRequiresCharging(false)
            .setRequiresDeviceIdle(false)
            .build()

        val workRequest = PeriodicWorkRequestBuilder<ServiceWatchdogWorker>(
            15, TimeUnit.MINUTES, 5, TimeUnit.MINUTES // flexInterval
        )
            .setConstraints(constraints)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
            .addTag("ServiceWatchdogTag")
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            "ServiceWatchdog",
            ExistingPeriodicWorkPolicy.UPDATE,
            workRequest
        )
    }
}
