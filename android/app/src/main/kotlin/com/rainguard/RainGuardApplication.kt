package com.rainguard

import android.app.Activity
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle

class RainGuardApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        registerActivityLifecycleCallbacks(foregroundTracker)
    }

    private val foregroundTracker = object : ActivityLifecycleCallbacks {
        private var startedActivities = 0

        override fun onActivityStarted(activity: Activity) {
            startedActivities++
            setForeground(true)
        }

        override fun onActivityStopped(activity: Activity) {
            startedActivities--
            if (startedActivities <= 0) {
                setForeground(false)
            }
        }

        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) = Unit
        override fun onActivityResumed(activity: Activity) = Unit
        override fun onActivityPaused(activity: Activity) = Unit
        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
        override fun onActivityDestroyed(activity: Activity) = Unit
    }

    private fun setForeground(foreground: Boolean) {
        if (isAppInForeground == foreground) return
        isAppInForeground = foreground
        foregroundListeners.toList().forEach { it(foreground) }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val monitoringChannel = NotificationChannel(
                CHANNEL_MONITORING,
                "Rain Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent notification while monitoring is active"
                setShowBadge(false)
            }

            val alertChannel = NotificationChannel(
                CHANNEL_ALERTS,
                "Rain Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when rain is approaching"
                enableVibration(true)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(monitoringChannel)
            manager.createNotificationChannel(alertChannel)
        }
    }

    companion object {
        const val CHANNEL_MONITORING = "rain_monitoring"
        const val CHANNEL_ALERTS = "rain_alerts"

        @Volatile
        var isAppInForeground: Boolean = false

        private val foregroundListeners = mutableListOf<(Boolean) -> Unit>()

        fun addForegroundListener(listener: (Boolean) -> Unit) {
            foregroundListeners.add(listener)
        }

        fun removeForegroundListener(listener: (Boolean) -> Unit) {
            foregroundListeners.remove(listener)
        }
    }
}
