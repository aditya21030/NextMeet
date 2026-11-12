package com.yousful.nextmeet

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.util.Locale

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
            "cheer" -> "⭐ Sparkle cheer sent to $name!"
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

    private fun decodeSafeWidgetBitmap(path: String?): Bitmap? {
        if (path.isNullOrEmpty()) return null
        val file = File(path)
        if (!file.exists() || !file.canRead()) return null
        return try {
            val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, boundsOpts)
            val maxDim = maxOf(boundsOpts.outWidth, boundsOpts.outHeight)
            var sampleSize = 1
            while (maxDim / sampleSize > 460) {
                sampleSize *= 2
            }
            val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sampleSize }
            BitmapFactory.decodeFile(path, decodeOpts)
        } catch (_: Throwable) {
            null
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        prefs: SharedPreferences
    ) {
        try {
            val name = prefs.getString("partnerName", null) ?: "Partner"
            val distance = prefs.getString("distance", null) ?: "-- km"
            val battery = prefs.getString("partnerBattery", null) ?: "--%"
            val isCharging = prefs.getBoolean("isPartnerCharging", false)
            val isAsleep = prefs.getBoolean("isPartnerAsleep", false)
            val origin = prefs.getString("originCity", null) ?: "You"
            val dest = prefs.getString("destCity", null) ?: name
            val countdownVal = prefs.getString("countdownVal", null) ?: "Soon ❤️"
            val isOnline = prefs.getBoolean("isPartnerOnline", false)
            val lastFeedback = prefs.getString("lastFeedback", null)
            val lastFeedbackTime = prefs.getLong("lastFeedbackTime", 0L)
            val activeWidgetId = prefs.getString("active_widget_id", null) ?: "distance_battery"
            val activeWidgetImg = prefs.getString("active_widget_img", null)

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // --- 1. WORKABLE TOUCH ACTION BUTTONS (DO NOT OPEN APP) ---
            fun createTouchPendingIntent(type: String, slotOffset: Int): PendingIntent {
                val touchIntent = Intent(context, OurPulseWidgetProvider::class.java).apply {
                    action = ACTION_TOUCH
                    data = Uri.parse("nextmeet://action/touch?type=$type&wid=$appWidgetId")
                    putExtra("type", type)
                    putExtra("appWidgetId", appWidgetId)
                }
                return PendingIntent.getBroadcast(
                    context,
                    appWidgetId * 10 + slotOffset,
                    touchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            // --- 2. DEEP LINKING ACTIONS (OPEN SPECIFIC APP SCREENS) ---
            fun createActivityPendingIntent(uriString: String, slotOffset: Int): PendingIntent {
                val activityIntent = Intent(context, MainActivity::class.java).apply {
                    action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
                    data = Uri.parse(uriString)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                val reqCode = appWidgetId * 100 + slotOffset
                if (Build.VERSION.SDK_INT >= 34) {
                    val options = ActivityOptions.makeBasic()
                    if (Build.VERSION.SDK_INT >= 35) {
                        options.setPendingIntentCreatorBackgroundActivityStartMode(
                            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                        )
                    } else {
                        options.pendingIntentBackgroundActivityStartMode =
                            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                    }
                    return PendingIntent.getActivity(context, reqCode, activityIntent, flags, options.toBundle())
                }
                return PendingIntent.getActivity(context, reqCode, activityIntent, flags)
            }

            val isRecentFeedback = (System.currentTimeMillis() - lastFeedbackTime) < 15000L && !lastFeedback.isNullOrEmpty()
            val deepLinkRoute = when (activeWidgetId) {
                "reunion_countdown", "trip_tracker", "next_event" -> "nextmeet://route/plan"
                "game_status" -> "nextmeet://route/games"
                "love_note" -> "nextmeet://route/vault"
                else -> "nextmeet://route/home"
            }

            val renderedBitmap = if (activeWidgetId != "distance_battery" && activeWidgetId != "quick_touch") {
                decodeSafeWidgetBitmap(activeWidgetImg)
            } else {
                null
            }

            if (activeWidgetId == "quick_touch") {
                views.setViewVisibility(R.id.widget_card, View.GONE)
                views.setViewVisibility(R.id.widget_rendered_wrapper, View.GONE)
                views.setViewVisibility(R.id.widget_quick_touch_card, View.VISIBLE)

                val qtTitle = if (isRecentFeedback) lastFeedback!! else "SEND TO ${name.uppercase(Locale.getDefault())}"
                views.setTextViewText(R.id.qt_header, qtTitle)
                views.setOnClickPendingIntent(R.id.btn_qt_miss, createTouchPendingIntent("miss", 1))
                views.setOnClickPendingIntent(R.id.btn_qt_hug, createTouchPendingIntent("hug", 2))
                views.setOnClickPendingIntent(R.id.btn_qt_touch, createTouchPendingIntent("touch", 3))
                views.setOnClickPendingIntent(R.id.btn_qt_cheer, createTouchPendingIntent("cheer", 4))
                views.setOnClickPendingIntent(R.id.widget_container, createActivityPendingIntent("nextmeet://route/home", 1))
            } else if (renderedBitmap != null) {
                views.setViewVisibility(R.id.widget_card, View.GONE)
                views.setViewVisibility(R.id.widget_quick_touch_card, View.GONE)
                views.setViewVisibility(R.id.widget_rendered_wrapper, View.VISIBLE)
                views.setImageViewBitmap(R.id.widget_rendered_image, renderedBitmap)

                if (isRecentFeedback) {
                    views.setTextViewText(R.id.widget_rendered_feedback, lastFeedback)
                    views.setViewVisibility(R.id.widget_rendered_feedback, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_rendered_feedback, View.GONE)
                }

                val openIntent = createActivityPendingIntent(deepLinkRoute, 2)
                views.setOnClickPendingIntent(R.id.widget_rendered_wrapper, openIntent)
                views.setOnClickPendingIntent(R.id.widget_rendered_image, openIntent)
                views.setOnClickPendingIntent(R.id.widget_container, openIntent)
            } else {
                views.setViewVisibility(R.id.widget_rendered_wrapper, View.GONE)
                views.setViewVisibility(R.id.widget_quick_touch_card, View.GONE)
                views.setViewVisibility(R.id.widget_card, View.VISIBLE)

                // Populate header & distance
                val battIcon = if (isCharging) "⚡" else "🔋"
                val statusSuffix = when {
                    isOnline -> " • Online"
                    isAsleep -> " • Asleep"
                    else -> " • Away"
                }
                views.setTextViewText(R.id.widget_battery, "$battIcon $battery$statusSuffix")
                views.setTextViewText(R.id.widget_distance, distance)
                views.setTextViewText(R.id.widget_partner_name, "❤️ $name")
                views.setTextViewText(R.id.widget_countdown_val, countdownVal)

                // Route vs Temporary Touch Action Feedback
                if (isRecentFeedback) {
                    views.setTextViewText(R.id.widget_feedback, lastFeedback)
                    views.setViewVisibility(R.id.widget_feedback, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_route, View.GONE)
                } else {
                    views.setTextViewText(R.id.widget_route, "$origin to $dest")
                    views.setViewVisibility(R.id.widget_route, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_feedback, View.GONE)
                }

                views.setOnClickPendingIntent(R.id.btn_action_miss, createTouchPendingIntent("miss", 1))
                views.setOnClickPendingIntent(R.id.btn_action_hug, createTouchPendingIntent("hug", 2))
                views.setOnClickPendingIntent(R.id.btn_action_touch, createTouchPendingIntent("touch", 3))
                views.setOnClickPendingIntent(R.id.btn_action_sync, createTouchPendingIntent("sync", 4))

                views.setOnClickPendingIntent(R.id.widget_container, createActivityPendingIntent("nextmeet://route/home", 3))
                views.setOnClickPendingIntent(R.id.widget_header_area, createActivityPendingIntent("nextmeet://route/home", 3))
                views.setOnClickPendingIntent(R.id.widget_partner_name, createActivityPendingIntent("nextmeet://route/home", 4))
                views.setOnClickPendingIntent(R.id.widget_countdown_val, createActivityPendingIntent("nextmeet://route/plan", 5))
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
