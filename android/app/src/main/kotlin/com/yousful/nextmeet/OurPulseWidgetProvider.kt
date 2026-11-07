package com.yousful.nextmeet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class OurPulseWidgetProvider : HomeWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        val name = prefs.getString("partnerName", null) ?: "Partner"
        val distance = prefs.getString("distance", null) ?: "1,506 km"
        val battery = prefs.getString("partnerBattery", null) ?: "87%"
        val isCharging = prefs.getBoolean("isPartnerCharging", false)
        val origin = prefs.getString("originCity", null) ?: "You"
        val dest = prefs.getString("destCity", null) ?: name
        val countdownVal = prefs.getString("countdownVal", null) ?: "Soon ❤️"
        val isOnline = prefs.getBoolean("isPartnerOnline", true)

        // Populate native fallback layout (NextMeet Pink & White Design System)
        val battIcon = if (isCharging) "⚡" else "🔋"
        val statusText = if (isOnline) "$battIcon $battery • Online now" else "$battIcon $battery"
        views.setTextViewText(R.id.widget_battery, statusText)
        views.setTextViewText(R.id.widget_distance, distance)
        views.setTextViewText(R.id.widget_route, "$origin to $dest")
        views.setTextViewText(R.id.widget_partner_name, "❤️ $name")
        views.setTextViewText(R.id.widget_countdown_val, countdownVal)

        // Check if Flutter-rendered pixel-perfect widget image is available
        val imagePath = prefs.getString("active_widget_img", null)
        var imageLoaded = false

        if (!imagePath.isNullOrEmpty()) {
            try {
                val file = File(imagePath)
                if (file.exists() && file.canRead()) {
                    val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_image, bitmap)
                        views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_native_layout, View.GONE)
                        imageLoaded = true
                    }
                }
            } catch (e: Exception) {
                imageLoaded = false
            }
        }

        if (!imageLoaded) {
            views.setViewVisibility(R.id.widget_image, View.GONE)
            views.setViewVisibility(R.id.widget_native_layout, View.VISIBLE)
        }

        // Tap widget to launch app
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (intent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_image, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_native_layout, pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
