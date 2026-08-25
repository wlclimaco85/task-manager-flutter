package com.washingtonclimaco.task_manager_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        criarCanalDeNotificacao()
    }

    private fun criarCanalDeNotificacao() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channelId = getString(resources.getIdentifier(
            "default_notification_channel_id",
            "string",
            packageName
        ))
        val channelName = getString(resources.getIdentifier(
            "default_notification_channel_name",
            "string",
            packageName
        ))
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_HIGH
        )
        channel.description = "Alertas e avisos do AppAcademia"

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
}
