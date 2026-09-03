package com.rainguard.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.rainguard.service.RainMonitorForegroundService

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Boot completed")

            // TODO: Check if monitoring was active before reboot
            // For MVP, we don't auto-start monitoring on boot
            // Just restore preferences

            // In V2, we could check preferences and auto-resume:
            // if (wasMonitoringActive) {
            //     val serviceIntent = Intent(context, RainMonitorForegroundService::class.java)
            //     context?.startForegroundService(serviceIntent)
            // }
        }
    }
}
