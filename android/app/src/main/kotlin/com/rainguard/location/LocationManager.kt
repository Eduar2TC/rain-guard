package com.rainguard.location

import android.annotation.SuppressLint
import android.content.Context
import android.os.Looper
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class LocationManager(private val context: Context) {

    private var fusedLocationClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null
    private var isUpdating = false

    var onLocationUpdate: ((LocationData) -> Unit)? = null

    data class LocationData(
        val latitude: Double,
        val longitude: Double,
        val accuracy: Float,
        val speed: Float,
        val bearing: Float,
        val timestamp: Long
    )

    @SuppressLint("MissingPermission")
    fun startUpdates(intervalMs: Long = 30000) {
        if (isUpdating) return

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            intervalMs
        ).apply {
            setMinUpdateIntervalMillis(intervalMs / 2)
            setMaxUpdateDelayMillis(intervalMs * 2)
        }.build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { location ->
                    onLocationUpdate?.invoke(
                        LocationData(
                            latitude = location.latitude,
                            longitude = location.longitude,
                            accuracy = location.accuracy,
                            speed = location.speed,
                            bearing = location.bearing,
                            timestamp = location.time
                        )
                    )
                }
            }
        }

        fusedLocationClient?.requestLocationUpdates(
            locationRequest,
            locationCallback!!,
            Looper.getMainLooper()
        )

        isUpdating = true
    }

    fun stopUpdates() {
        locationCallback?.let { callback ->
            fusedLocationClient?.removeLocationUpdates(callback)
        }
        locationCallback = null
        fusedLocationClient = null
        isUpdating = false
    }

    fun updateInterval(intervalMs: Long) {
        if (isUpdating) {
            stopUpdates()
            startUpdates(intervalMs)
        }
    }

    fun isUpdating(): Boolean = isUpdating
}
