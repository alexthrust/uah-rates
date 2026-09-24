import 'package:flutter_test/flutter_test.dart';
import 'package:uah_rates/models/rates.dart';
import 'package:uah_rates/services/widget_publisher.dart';

SourceResult result(RateSource source, DateTime fetchedAt, {bool stale = false}) =>
    SourceResult(
      source: source,
      isStale: stale,
      data: SourceRates(
        source: source,
        rates: const {Currency.usd: Rate(buy: 44.6, sell: 45.4)},
        asOf: null,
        fetchedAt: fetchedAt,
      ),
    );

void main() {
  test('formatWidgetRate_exchangeOffice_showsBuySlashSell', () {
    expect(formatWidgetRate(const Rate(buy: 44.6, sell: 45.4)), '44.60/45.40');
  });

  test('formatWidgetRate_official_showsSingleValue', () {
    expect(formatWidgetRate(const Rate.official(44.9729)), '44.97');
  });

  test('formatWidgetUpdated_allFresh_showsLatestFetchTime', () {
    final text = formatWidgetUpdated([
      result(RateSource.nbu, DateTime(2026, 9, 24, 16, 5)),
      result(RateSource.lion, DateTime(2026, 9, 24, 16, 12)),
    ]);
    expect(text, '16:12');
  });

  test('formatWidgetUpdated_anyStale_prefixesWarning', () {
    final text = formatWidgetUpdated([
      result(RateSource.nbu, DateTime(2026, 9, 24, 16, 12)),
      result(RateSource.rulya, DateTime(2026, 9, 24, 9, 0), stale: true),
    ]);
    expect(text, '⚠ 16:12');
  });

  test('formatWidgetUpdated_noData_showsNoData', () {
    expect(
      formatWidgetUpdated([const SourceResult(source: RateSource.nbu, isStale: true)]),
      'No data',
    );
  });
}
