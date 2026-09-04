package com.rainguard.service

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.rainguard.MainActivity
import com.rainguard.RainGuardApplication
import com.rainguard.R
import com.rainguard.location.LocationManager
import com.rainguard.weather.WeatherPlatformBridge
import com.rainguard.notification.RainNotificationManager
import com.rainguard.overlay.RainBubbleManager
import kotlinx.coroutines.*
import kotlin.math.abs

class RainMonitorForegroundService : Service() {

    companion object {
        private const val TAG = "RainMonitorService"
        private const val NOTIFICATION_ID = 1001
        private const val ALERT_NOTIFICATION_ID = 1002
        private const val ACTION_START = "com.rainguard.ACTION_START"
        private const val ACTION_STOP = "com.rainguard.ACTION_STOP"
        private const val ACTION_PAUSE = "com.rainguard.ACTION_PAUSE"
        private const val ACTION_RESUME = "com.rainguard.ACTION_RESUME"
        private const val ACTION_ENABLE_BUBBLE = "com.rainguard.ACTION_ENABLE_BUBBLE"
        private const val ACTION_DISABLE_BUBBLE = "com.rainguard.ACTION_DISABLE_BUBBLE"

        // Polling intervals (milliseconds)
        private const val NORMAL_POLLING = 300_000L // 5 min
        private const val WATCH_POLLING = 240_000L // 4 min
        private const val APPROACHING_POLLING = 180_000L // 3 min
        private const val WARNING_POLLING = 90_000L // 1.5 min
        private const val RAINING_POLLING = 180_000L // 3 min

        // Thresholds
        private const val LIGHT_RAIN_THRESHOLD = 0.5
        private const val MODERATE_RAIN_THRESHOLD = 4.0
        private const val IMMINENT_THRESHOLD_MINUTES = 2
        private const val WARNING_THRESHOLD_MINUTES = 5
        private const val APPROACHING_THRESHOLD_MINUTES = 10
        private const val WATCH_THRESHOLD_MINUTES = 15
    }

    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var wakeLock: PowerManager.WakeLock? = null

    private var foregroundListener: ((Boolean) -> Unit)? = null

    private lateinit var locationManager: LocationManager
    private lateinit var weatherBridge: WeatherPlatformBridge
    private lateinit var notificationManager: RainNotificationManager
    private lateinit var bubbleManager: RainBubbleManager

    private var isRunning = false
    private var isPaused = false
    private var bubbleEnabled = false
    private var currentPollingInterval = NORMAL_POLLING
    private var pollingJob: Job? = null

    // State
    private var currentLat: Double = 0.0
    private var currentLon: Double = 0.0
    private var currentSpeed: Float = 0f
    private var currentBearing: Float = 0f
    private var currentAccuracy: Float = 0f
    private var lastPrecipitation: Double = 0.0
    private var lastEtaMinutes: Int = -1
    private var currentState: String = "idle"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")

        locationManager = LocationManager(this)
        weatherBridge = WeatherPlatformBridge(this)
        notificationManager = RainNotificationManager(this)
        bubbleManager = RainBubbleManager(this)
        bubbleEnabled = getSharedPreferences("rainguard_prefs", Context.MODE_PRIVATE)
            .getBoolean("bubble_enabled", false)
        setupBubbleCallbacks()

        foregroundListener = { _ ->
            Handler(Looper.getMainLooper()).post { updateBubbleVisibility() }
        }
        RainGuardApplication.addForegroundListener(foregroundListener!!)
    }

    private fun updateBubbleVisibility() {
        if (!isRunning || !bubbleEnabled) {
            bubbleManager.hide()
            return
        }
        if (isPaused) {
            bubbleManager.hide()
            return
        }
        if (!RainGuardApplication.isAppInForeground) {
            showBubbleInternal()
        } else {
            bubbleManager.hide()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startMonitoring()
            ACTION_STOP -> stopMonitoring()
            ACTION_PAUSE -> pauseMonitoring()
            ACTION_RESUME -> resumeMonitoring()
            ACTION_ENABLE_BUBBLE -> enableBubble(true)
            ACTION_DISABLE_BUBBLE -> enableBubble(false)
            else -> {
                if (!isRunning) {
                    startMonitoring()
                }
            }
        }
        return START_STICKY
    }

    private fun enableBubble(enabled: Boolean) {
        bubbleEnabled = enabled
        getSharedPreferences("rainguard_prefs", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("bubble_enabled", enabled)
            .apply()
        Log.d(TAG, "Bubble ${if (enabled) "enabled" else "disabled"}")

        updateBubbleVisibility()
    }

    private fun showBubble() {
        updateBubbleVisibility()
    }

    private fun showBubbleInternal() {
        bubbleManager.show()
        bubbleManager.restorePosition()
        bubbleManager.updateState(currentState, lastEtaMinutes)
    }

    private fun setupBubbleCallbacks() {
        bubbleManager.onTap = {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            startActivity(intent)
        }
    }

    private fun startMonitoring() {
        Log.d(TAG, "Starting monitoring")
        isRunning = true
        isPaused = false

        acquireWakeLock()
        startForeground(NOTIFICATION_ID, createNotification("RainGuard activo"))
        startLocationUpdates()
        startPolling()
        showBubble()
    }

    private fun stopMonitoring() {
        Log.d(TAG, "Stopping monitoring")
        isRunning = false
        isPaused = false

        pollingJob?.cancel()
        locationManager.stopUpdates()
        releaseWakeLock()
        bubbleManager.hide()

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun pauseMonitoring() {
        Log.d(TAG, "Pausing monitoring")
        isPaused = true
        pollingJob?.cancel()
        locationManager.stopUpdates()
        bubbleManager.hide()
        updateNotification("RainGuard pausado")
    }

    private fun resumeMonitoring() {
        Log.d(TAG, "Resuming monitoring")
        isPaused = false
        startLocationUpdates()
        startPolling()
        updateNotification("RainGuard activo")
        showBubble()
    }

    private fun startLocationUpdates() {
        locationManager.onLocationUpdate = { location ->
            currentLat = location.latitude
            currentLon = location.longitude
            currentSpeed = location.speed
            currentBearing = location.bearing
            currentAccuracy = location.accuracy

            // Trigger weather fetch on location update
            serviceScope.launch {
                fetchAndUpdateWeather()
            }
        }
        locationManager.startUpdates(intervalMs = currentPollingInterval)
    }

    private fun startPolling() {
        pollingJob?.cancel()
        pollingJob = serviceScope.launch {
            while (isActive && isRunning && !isPaused) {
                fetchAndUpdateWeather()
                delay(currentPollingInterval)
            }
        }
    }

    private suspend fun fetchAndUpdateWeather() {
        try {
            val weatherData = weatherBridge.fetchWeather(currentLat, currentLon)
            if (weatherData != null) {
                lastPrecipitation = weatherData.precipitation
                lastEtaMinutes = weatherData.precipitationEtaMinutes ?: -1
                updateState()
                updateNotificationBasedOnState()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching weather", e)
        }
    }

    private fun updateState() {
        val newState = calculateState(lastPrecipitation, lastEtaMinutes)
        if (newState != currentState) {
            Log.d(TAG, "State changed: $currentState -> $newState")
            currentState = newState
            adjustPollingInterval()
        }
        if (bubbleManager.isShowing()) {
            bubbleManager.updateState(currentState, lastEtaMinutes)
        }
    }

    private fun calculateState(precipitation: Double, etaMinutes: Int): String {
        return when {
            precipitation > MODERATE_RAIN_THRESHOLD -> "raining"
            precipitation > LIGHT_RAIN_THRESHOLD -> "raining"
            etaMinutes in 0..IMMINENT_THRESHOLD_MINUTES -> "imminent"
            etaMinutes in 0..WARNING_THRESHOLD_MINUTES -> "warning"
            etaMinutes in 0..APPROACHING_THRESHOLD_MINUTES -> "approaching"
            etaMinutes in 0..WATCH_THRESHOLD_MINUTES -> "watch"
            else -> "idle"
        }
    }

    private fun adjustPollingInterval() {
        val newInterval = when (currentState) {
            "imminent" -> WARNING_POLLING
            "warning" -> WARNING_POLLING
            "approaching" -> APPROACHING_POLLING
            "watch" -> WATCH_POLLING
            else -> NORMAL_POLLING
        }

        if (newInterval != currentPollingInterval) {
            currentPollingInterval = newInterval
            Log.d(TAG, "Polling interval adjusted to: ${newInterval / 1000}s")
            locationManager.updateInterval(newInterval)
        }
    }

    private fun updateNotificationBasedOnState() {
        val contentText = when (currentState) {
            "raining" -> "RainGuard · Está lloviendo"
            "imminent" -> "RainGuard · Lluvia inminente (~$lastEtaMinutes min)"
            "warning" -> "RainGuard · Lluvia en ~$lastEtaMinutes min"
            "approaching" -> "RainGuard · Lluvia acercándose (~$lastEtaMinutes min)"
            "watch" -> "RainGuard · Posible lluvia (~$lastEtaMinutes min)"
            else -> "RainGuard activo · Sin lluvia cercana"
        }
        updateNotification(contentText)

        // Show alert notification for warning states
        if (currentState in listOf("imminent", "warning", "raining")) {
            showAlertNotification()
        }
    }

    private fun sendStateToFlutter() {
        Log.d(TAG, "State: $currentState (eta=$lastEtaMinutes min, precip=$lastPrecipitation)")
    }

    private fun createNotification(contentText: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = PendingIntent.getService(
            this, 1,
            Intent(this, RainMonitorForegroundService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseIntent = PendingIntent.getService(
            this, 2,
            Intent(this, RainMonitorForegroundService::class.java).apply {
                action = if (isPaused) ACTION_RESUME else ACTION_PAUSE
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, RainGuardApplication.CHANNEL_MONITORING)
            .setContentTitle("RainGuard")
            .setContentText(contentText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .addAction(R.mipmap.ic_launcher, if (isPaused) "Reanudar" else "Pausar", pauseIntent)
            .addAction(R.mipmap.ic_launcher, "Detener", stopIntent)
            .build()
    }

    private fun updateNotification(contentText: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, createNotification(contentText))
    }

    private fun showAlertNotification() {
        val title = when (currentState) {
            "imminent" -> "🚨 Lluvia inminente"
            "warning" -> "⚠️ Lluvia acercándose"
            "raining" -> "🌧️ Está lloviendo"
            else -> return
        }

        val body = when (currentState) {
            "imminent" -> "Refúgiate ahora"
            "warning" -> "Busca refugio · ~$lastEtaMinutes min"
            "raining" -> "Lluvia detectada en tu ubicación"
            else -> return
        }

        notificationManager.showAlertNotification(title, body)
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "RainGuard::MonitoringWakeLock"
        ).apply {
            acquire() // No timeout - released on stop/destroy
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        locationManager.stopUpdates()
        releaseWakeLock()
        bubbleManager.hide()
        foregroundListener?.let { RainGuardApplication.removeForegroundListener(it) }
        Log.d(TAG, "Service destroyed")
    }
}
