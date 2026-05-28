package com.example.vpn

import android.net.VpnService
import android.os.IBinder

class VpnService : VpnService() {
    override fun onBind(intent: android.content.Intent?): IBinder? {
        // This service is only used for the VPN interface, we don't bind to it.
        return null
    }

    override fun onStartCommand(intent: android.content.Intent?, flags: Int, startId: Int): Int {
        // Handle start commands if needed
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}