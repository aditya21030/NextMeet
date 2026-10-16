package com.yousful.nextmeet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class OurPulseWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Use HomeWidgetPreferences for correct sync with home_widget plugin
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val name = prefs.getString("partnerName", null) ?: "MY LOVE"
        val distance = prefs.getString("distance", null) ?: "0 KM"
        val daysTogether = prefs.getString("daysTogether", null) ?: "0 Days"
        val battery = prefs.getString("partnerBattery", null) ?: "100%"
        val isCharging = prefs.getBoolean("isPartnerCharging", false)
        val origin = prefs.getString("originCity", null) ?: "YOU"
        val dest = prefs.getString("destCity", null) ?: "LOVE"
        val countdownVal = prefs.getString("countdownVal", null) ?: prefs.getString("nextMeet", null) ?: "Soon ❤️"
        val countdownSub = prefs.getString("countdownSub", null) ?: "NEXT REUNION"
        val reunionDate = prefs.getString("reunionDate", null) ?: "SOON"

        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        // Route & Header
        views.setTextViewText(R.id.widget_partner_name, name.uppercase())
        views.setTextViewText(R.id.widget_origin_city, origin.take(14).uppercase())
        views.setTextViewText(R.id.widget_dest_city, dest.take(14).uppercase())
        views.setTextViewText(R.id.widget_distance, distance)

        // Live Battery with dynamic charging indicator
        val batteryIcon = if (isCharging) "⚡" else "🔋"
        views.setTextViewText(R.id.widget_battery, "$batteryIcon $battery")

        // Countdown Hero
        views.setTextViewText(R.id.widget_countdown_val, countdownVal)
        views.setTextViewText(R.id.widget_countdown_sub, countdownSub)

        // Footer & Legacy compatibility
        views.setTextViewText(R.id.widget_reunion_date, reunionDate)
        views.setTextViewText(R.id.widget_days_together, daysTogether)
        views.setTextViewText(R.id.widget_next_meet, countdownVal)

        // Launch app on widget tap
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (intent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
