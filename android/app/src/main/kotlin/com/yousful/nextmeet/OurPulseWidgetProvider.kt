package com.yousful.nextmeet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class OurPulseWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_TOUCH = "com.yousful.nextmeet.ACTION_TOUCH"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOUCH) {
            handleTouchAction(context, intent)
        }
    }

    private fun handleTouchAction(context: Context, intent: Intent) {
        val type = intent.getStringExtra("type") ?: "touch"
        val prefs = HomeWidgetPlugin.getData(context)
        val name = prefs.getString("partnerName", null) ?: "Partner"
        val appWidgetManager = AppWidgetManager.getInstance(context)

        val feedbackText = when (type) {
            "miss" -> "❤️ Miss you sent to $name!"
            "hug" -> "🤗 Warm hug sent to $name!"
            "touch" -> "⚡ Touch sent to $name!"
            "sync" -> "💓 Heartbeat synced!"
            else -> "❤️ Sent to $name!"
        }

        // Store feedback message and timestamp (shown for 15 seconds)
        prefs.edit()
            .putString("lastFeedback", feedbackText)
            .putLong("lastFeedbackTime", System.currentTimeMillis())
            .apply()

        // 1. Immediately update all widget instances to show the confirmation without launching the app
        val componentName = ComponentName(context, OurPulseWidgetProvider::class.java)
        val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
        for (id in widgetIds) {
            updateAppWidget(context, appWidgetManager, id, prefs)
        }

        // 2. Dispatch background broadcast so Flutter / Firebase sends the real-time cloud touch & FCM
        try {
            val bgIntent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                action = "es.antonborri.home_widget.action.BACKGROUND"
                data = Uri.parse("nextmeet://action/touch?type=$type")
            }
            context.sendBroadcast(bgIntent)
        } catch (_: Exception) {}
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val prefs = HomeWidgetPlugin.getData(context)
        updateAppWidget(context, appWidgetManager, appWidgetId, prefs)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        prefs: SharedPreferences
    ) {
        try {
            val name = prefs.getString("partnerName", null) ?: "Partner"
            val distance = prefs.getString("distance", null) ?: "1,506 km"
            val battery = prefs.getString("partnerBattery", null) ?: "87%"
            val isCharging = prefs.getBoolean("isPartnerCharging", false)
            val origin = prefs.getString("originCity", null) ?: "You"
            val dest = prefs.getString("destCity", null) ?: name
            val countdownVal = prefs.getString("countdownVal", null) ?: "Soon ❤️"
            val isOnline = prefs.getBoolean("isPartnerOnline", true)
            val lastFeedback = prefs.getString("lastFeedback", null)
            val lastFeedbackTime = prefs.getLong("lastFeedbackTime", 0L)

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // Populate header & distance
            val battIcon = if (isCharging) "⚡" else "🔋"
            val statusText = if (isOnline) "$battIcon $battery • Online now" else "$battIcon $battery"
            views.setTextViewText(R.id.widget_battery, statusText)
            views.setTextViewText(R.id.widget_distance, distance)
            views.setTextViewText(R.id.widget_partner_name, "❤️ $name")
            views.setTextViewText(R.id.widget_countdown_val, countdownVal)

            // Route vs Temporary Touch Action Feedback
            val isRecentFeedback = (System.currentTimeMillis() - lastFeedbackTime) < 15000L
            if (isRecentFeedback && !lastFeedback.isNullOrEmpty()) {
                views.setTextViewText(R.id.widget_feedback, lastFeedback)
                views.setViewVisibility(R.id.widget_feedback, View.VISIBLE)
                views.setViewVisibility(R.id.widget_route, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_route, "$origin to $dest")
                views.setViewVisibility(R.id.widget_route, View.VISIBLE)
                views.setViewVisibility(R.id.widget_feedback, View.GONE)
            }

            // --- 1. WORKABLE TOUCH ACTION BUTTONS (DO NOT OPEN APP) ---
            fun createTouchPendingIntent(type: String, requestCode: Int): PendingIntent {
                val touchIntent = Intent(context, OurPulseWidgetProvider::class.java).apply {
                    action = ACTION_TOUCH
                    putExtra("type", type)
                    putExtra("appWidgetId", appWidgetId)
                }
                return PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    touchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            views.setOnClickPendingIntent(R.id.btn_action_miss, createTouchPendingIntent("miss", 201))
            views.setOnClickPendingIntent(R.id.btn_action_hug, createTouchPendingIntent("hug", 202))
            views.setOnClickPendingIntent(R.id.btn_action_touch, createTouchPendingIntent("touch", 203))
            views.setOnClickPendingIntent(R.id.btn_action_sync, createTouchPendingIntent("sync", 204))

            // --- 2. DEEP LINKING ACTIONS (OPEN SPECIFIC APP SCREENS) ---
            val mainIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (mainIntent != null) {
                // Tapping distance / route header opens Home Screen
                val homePendingIntent = PendingIntent.getActivity(
                    context,
                    100,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_header_area, homePendingIntent)

                // Tapping countdown pill opens Plan / Reunion Hub
                val planIntent = Intent(mainIntent).apply {
                    data = Uri.parse("nextmeet://route/plan")
                }
                val planPendingIntent = PendingIntent.getActivity(
                    context,
                    101,
                    planIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_countdown_val, planPendingIntent)

                // Tapping partner name opens Home / Chat
                val chatIntent = Intent(mainIntent).apply {
                    data = Uri.parse("nextmeet://route/home")
                }
                val chatPendingIntent = PendingIntent.getActivity(
                    context,
                    102,
                    chatIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_partner_name, chatPendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            // Absolute safety fallback
            try {
                val fallbackViews = RemoteViews(context.packageName, R.layout.widget_layout)
                appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
            } catch (_: Exception) {}
        }
    }
}
