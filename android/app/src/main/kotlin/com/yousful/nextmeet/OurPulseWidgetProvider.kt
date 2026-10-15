package com.yousful.nextmeet

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences

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
        val name = prefs.getString("partnerName", null) ?: "PARTNER"
        val mood = prefs.getString("partnerMood", null) ?: "✨"
        val distance = prefs.getString("distance", null) ?: "0.0 KM"
        val daysTogether = prefs.getString("daysTogether", null) ?: "0 Days"
        val nextMeet = prefs.getString("nextMeet", null) ?: "Soon"
        val lastSeen = prefs.getString("lastSeen", "Syncing...")

        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        views.setTextViewText(R.id.widget_partner_name, name.uppercase())
        views.setTextViewText(R.id.widget_distance, distance)
        views.setTextViewText(R.id.widget_days_together, daysTogether)
        views.setTextViewText(R.id.widget_next_meet, nextMeet)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
