package com.rainguard

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.rainguard.location.LocationManager
import com.rainguard.permissions.PermissionManager
import com.rainguard.notification.RainNotificationManager
import com.rainguard.overlay.RainBubbleManager
import com.rainguard.battery.BatteryMonitor
import com.rainguard.service.RainMonitorForegroundService

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "rainguard/monitoring"
    private val EVENT_CHANNEL = "rainguard/events"
    private val LOCATION_EVENT_CHANNEL = "rainguard/location"

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var locationEventChannel: EventChannel

    private lateinit var locationManager: LocationManager
    private lateinit var permissionManager: PermissionManager
    private lateinit var notificationManager: RainNotificationManager
    private lateinit var bubbleManager: RainBubbleManager
    private lateinit var batteryMonitor: BatteryMonitor

    private var locationEventSink: EventChannel.EventSink? = null
    private var eventEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        locationManager = LocationManager(this)
        permissionManager = PermissionManager(this)
        notificationManager = RainNotificationManager(this)
        bubbleManager = RainBubbleManager(this)
        batteryMonitor = BatteryMonitor(this)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        locationEventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_EVENT_CHANNEL)

        setupMethodChannel()
        setupEventChannels()
        setupBubbleCallbacks()
        setupBatteryMonitor()
    }

    private fun setupMethodChannel() {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                // Monitoring
                "startMonitoring" -> {
                    startForegroundService()
                    result.success(true)
                }
                "stopMonitoring" -> {
                    stopForegroundService()
                    result.success(true)
                }
                "pauseMonitoring" -> {
                    val intent = Intent(this, RainMonitorForegroundService::class.java).apply {
                        action = "com.rainguard.ACTION_PAUSE"
                    }
                    startService(intent)
                    result.success(true)
                }
                "resumeMonitoring" -> {
                    val intent = Intent(this, RainMonitorForegroundService::class.java).apply {
                        action = "com.rainguard.ACTION_RESUME"
                    }
                    startService(intent)
                    result.success(true)
                }
                "isMonitoring" -> {
                    result.success(false) // TODO: Check actual state
                }

                // Location
                "startLocationUpdates" -> {
                    startLocationUpdates()
                    result.success(true)
                }
                "stopLocationUpdates" -> {
                    locationManager.stopUpdates()
                    result.success(true)
                }
                "getLastKnownLocation" -> {
                    result.success(null)
                }
                "hasLocationPermission" -> {
                    result.success(permissionManager.hasLocationPermission())
                }
                "requestLocationPermission" -> {
                    permissionManager.requestLocationPermission(this)
                    result.success(true)
                }
                "requestBackgroundLocationPermission" -> {
                    permissionManager.requestBackgroundLocationPermission(this)
                    result.success(true)
                }

                // Overlay
                "showBubble" -> {
                    if (permissionManager.hasOverlayPermission()) {
                        bubbleManager.show()
                        bubbleManager.restorePosition()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "hideBubble" -> {
                    bubbleManager.hide()
                    result.success(true)
                }
                "setBubblePosition" -> {
                    val x = call.argument<Int>("x") ?: 0
                    val y = call.argument<Int>("y") ?: 0
                    bubbleManager.setPosition(x, y)
                    result.success(true)
                }
                "getBubblePosition" -> {
                    val (x, y) = bubbleManager.getPosition()
                    result.success(hashMapOf("x" to x, "y" to y))
                }
                "isBubbleVisible" -> {
                    result.success(bubbleManager.isShowing())
                }
                "updateBubbleState" -> {
                    val state = call.argument<String>("state") ?: "idle"
                    val etaMinutes = call.argument<Int>("etaMinutes")
                    bubbleManager.updateState(state, etaMinutes)
                    result.success(true)
                }

                // Permissions
                "requestOverlayPermission" -> {
                    permissionManager.requestOverlayPermission(this)
                    result.success(true)
                }
                "requestNotificationPermission" -> {
                    permissionManager.requestNotificationPermission(this)
                    result.success(true)
                }

                // Settings
                "setSettings" -> {
                    result.success(true)
                }

                // Battery
                "checkBattery" -> {
                    val batteryInfo = batteryMonitor.getBatteryInfo()
                    if (batteryInfo != null) {
                        result.success(hashMapOf(
                            "level" to batteryInfo.level,
                            "percentage" to batteryInfo.percentage,
                            "isCharging" to batteryInfo.isCharging,
                            "chargingSource" to batteryInfo.chargingSource,
                            "isPowerSaveMode" to batteryInfo.isPowerSaveMode,
                            "isIgnoringBatteryOptimizations" to batteryInfo.isIgnoringBatteryOptimizations
                        ))
                    } else {
                        result.success(null)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    batteryMonitor.requestIgnoreBatteryOptimizations()
                    result.success(true)
                }

                // Notifications
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val priority = call.argument<Int>("priority") ?: 0
                    notificationManager.showAlertNotification(title, body)
                    result.success(true)
                }
                "updateNotification" -> {
                    val body = call.argument<String>("body") ?: ""
                    notificationManager.showMonitoringNotification(body)
                    result.success(true)
                }
                "cancelNotification" -> {
                    notificationManager.cancelAlertNotification()
                    result.success(true)
                }

                // Sound/Vibration
                "playAlertSound" -> {
                    notificationManager.playAlertSound()
                    result.success(true)
                }
                "vibrate" -> {
                    notificationManager.vibrate()
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setupEventChannels() {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventEventSink = null
            }
        })

        locationEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                locationEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                locationEventSink = null
            }
        })
    }

    private fun setupBubbleCallbacks() {
        bubbleManager.onTap = {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            startActivity(intent)
        }

        bubbleManager.onLongPress = {
            methodChannel.invokeMethod("onBubbleLongPress", null)
        }

        bubbleManager.onPositionChanged = { x, y ->
            methodChannel.invokeMethod("onBubblePositionChanged", hashMapOf("x" to x, "y" to y))
        }
    }

    private fun setupBatteryMonitor() {
        batteryMonitor.startListening { batteryInfo ->
            runOnUiThread {
                methodChannel.invokeMethod("onBatteryChanged", hashMapOf(
                    "level" to batteryInfo.level,
                    "percentage" to batteryInfo.percentage,
                    "isCharging" to batteryInfo.isCharging,
                    "chargingSource" to batteryInfo.chargingSource,
                    "isPowerSaveMode" to batteryInfo.isPowerSaveMode,
                    "isIgnoringBatteryOptimizations" to batteryInfo.isIgnoringBatteryOptimizations
                ))
            }
        }
    }

    private fun startLocationUpdates() {
        locationManager.onLocationUpdate = { locationData ->
            val event = hashMapOf<String, Any>(
                "latitude" to locationData.latitude,
                "longitude" to locationData.longitude,
                "accuracy" to locationData.accuracy,
                "speed" to locationData.speed,
                "bearing" to locationData.bearing,
                "timestamp" to locationData.timestamp
            )
            runOnUiThread {
                locationEventSink?.success(event)
            }
        }
        locationManager.startUpdates()
    }

    private fun startForegroundService() {
        val intent = Intent(this, RainMonitorForegroundService::class.java).apply {
            action = "com.rainguard.ACTION_START"
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopForegroundService() {
        val intent = Intent(this, RainMonitorForegroundService::class.java).apply {
            action = "com.rainguard.ACTION_STOP"
        }
        startService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            PermissionManager.REQUEST_OVERLAY -> {
                val hasPermission = permissionManager.hasOverlayPermission()
                methodChannel.invokeMethod("onOverlayPermissionResult", hasPermission)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val granted = grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED

        when (requestCode) {
            PermissionManager.REQUEST_LOCATION -> {
                methodChannel.invokeMethod("onLocationPermissionResult", granted)
            }
            PermissionManager.REQUEST_BACKGROUND_LOCATION -> {
                methodChannel.invokeMethod("onBackgroundLocationPermissionResult", granted)
            }
            PermissionManager.REQUEST_NOTIFICATION -> {
                methodChannel.invokeMethod("onNotificationPermissionResult", granted)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        bubbleManager.hide()
        batteryMonitor.stopListening()
    }
}
