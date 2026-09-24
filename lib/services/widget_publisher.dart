import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/rates.dart';

const androidWidgetProvider = 'com.alexeyb.uah_rates.RatesWidgetProvider';

Future<void> publishToWidget(List<SourceResult> results) async {
  for (final result in results) {
    for (final currency in Currency.values) {
      final rate = result.data?.rates[currency];
      await HomeWidget.saveWidgetData<String>(
        '${result.source.name}_${currency.name}',
        rate == null ? '—' : formatWidgetRate(rate),
      );
    }
  }
  await HomeWidget.saveWidgetData<String>('updated', formatWidgetUpdated(results));
  await HomeWidget.updateWidget(qualifiedAndroidName: androidWidgetProvider);
}

String formatWidgetRate(Rate rate) => rate.isOfficial
    ? rate.buy.toStringAsFixed(2)
    : '${rate.buy.toStringAsFixed(2)}/${rate.sell.toStringAsFixed(2)}';

String formatWidgetUpdated(List<SourceResult> results) {
  final fetched = results
      .map((r) => r.data?.fetchedAt)
      .whereType<DateTime>()
      .fold<DateTime?>(null, (latest, t) => latest == null || t.isAfter(latest) ? t : latest);
  if (fetched == null) return 'No data';
  final time = DateFormat('HH:mm').format(fetched);
  return results.any((r) => r.isStale) ? '⚠ $time' : time;
}
