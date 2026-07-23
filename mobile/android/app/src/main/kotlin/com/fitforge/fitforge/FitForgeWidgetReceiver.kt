package com.fitforge.fitforge

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FitForgeWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val water = widgetData.getString("water_ml", "0")
                val streak = widgetData.getString("streak_count", "0")

                setTextViewText(R.id.widget_water_text, "$water ml")
                setTextViewText(R.id.widget_streak_text, "$streak Days")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
