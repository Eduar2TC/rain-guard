package com.rainguard.weather

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

class WeatherPlatformBridge(private val context: Context) {

    private var lastWeatherData: WeatherData? = null
    private var lastFetchTime: Long = 0

    data class WeatherData(
        val precipitation: Double,
        val rain: Double,
        val showers: Double,
        val temperature: Double,
        val windSpeed: Double,
        val windDirection: Double,
        val windGust: Double,
        val weatherCode: Int,
        val timestamp: Long,
        val sourceTimestamp: Long
    )

    suspend fun fetchWeather(latitude: Double, longitude: Double): WeatherData? {
        if (!isNetworkAvailable()) return null

        return withContext(Dispatchers.IO) {
            try {
                val url = buildUrl(latitude, longitude)
                val connection = URL(url).openConnection() as HttpURLConnection

                connection.connectTimeout = 10000
                connection.readTimeout = 10000

                val response = connection.inputStream.bufferedReader().readText()
                val json = JSONObject(response)

                val current = json.getJSONObject("current")

                val weatherData = WeatherData(
                    precipitation = current.getDouble("precipitation"),
                    rain = current.getDouble("rain"),
                    showers = current.getDouble("showers"),
                    temperature = current.getDouble("temperature_2m"),
                    windSpeed = current.getDouble("wind_speed_10m"),
                    windDirection = current.getDouble("wind_direction_10m"),
                    windGust = current.getDouble("wind_gusts_10m"),
                    weatherCode = current.getInt("weather_code"),
                    timestamp = System.currentTimeMillis(),
                    sourceTimestamp = System.currentTimeMillis()
                )

                lastWeatherData = weatherData
                lastFetchTime = System.currentTimeMillis()

                weatherData
            } catch (e: Exception) {
                null
            }
        }
    }

    fun getLastWeatherData(): WeatherData? = lastWeatherData

    fun isDataStale(maxAgeMs: Long = 600000): Boolean {
        if (lastWeatherData == null) return true
        return System.currentTimeMillis() - lastFetchTime > maxAgeMs
    }

    private fun buildUrl(latitude: Double, longitude: Double): String {
        return "https://api.open-meteo.com/v1/forecast" +
                "?latitude=$latitude" +
                "&longitude=$longitude" +
                "&current=precipitation,rain,showers,temperature_2m," +
                "wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code" +
                "&minutely_15=precipitation" +
                "&forecast_days=1" +
                "&timezone=auto"
    }

    private fun isNetworkAvailable(): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }
}
