package com.alexeyb.uah_rates

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class RatesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            RemoteViews(
                mapOf(
                    SizeF(100f, 60f) to buildViews(context, widgetData, compact = true),
                    SizeF(220f, 100f) to buildViews(context, widgetData, compact = false),
                )
            )
        } else {
            buildViews(context, widgetData, compact = false)
        }
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }

    private fun buildViews(
        context: Context,
        data: SharedPreferences,
        compact: Boolean,
    ): RemoteViews {
        val layout = if (compact) R.layout.rates_widget_compact else R.layout.rates_widget
        val fields = if (compact) USD_FIELDS else USD_FIELDS + EUR_FIELDS

        return RemoteViews(context.packageName, layout).apply {
            fields.forEach { (viewId, key) -> setTextViewText(viewId, data.getString(key, "—")) }
            setTextViewText(R.id.updated, data.getString("updated", ""))
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            if (!compact) {
                setOnClickPendingIntent(
                    R.id.refresh,
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("uahrates://refresh")),
                )
            }
        }
    }

    private companion object {
        val USD_FIELDS = listOf(
            R.id.nbu_usd to "nbu_usd",
            R.id.rulya_usd to "rulya_usd",
            R.id.lion_usd to "lion_usd",
        )
        val EUR_FIELDS = listOf(
            R.id.nbu_eur to "nbu_eur",
            R.id.rulya_eur to "rulya_eur",
            R.id.lion_eur to "lion_eur",
        )
    }
}
