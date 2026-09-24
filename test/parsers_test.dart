import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uah_rates/models/rates.dart';
import 'package:uah_rates/sources/parsers.dart';

String fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync().replaceFirst('﻿', '');

void main() {
  final now = DateTime(2026, 9, 24, 17);

  test('parseNbu_liveFixture_returnsUsdAndEur', () {
    final result = parseNbu(fixture('nbu.json'), now);

    expect(result.rates[Currency.usd]!.buy, greaterThan(10));
    expect(result.rates[Currency.eur]!.buy, greaterThan(10));
    expect(result.rates[Currency.usd]!.isOfficial, isTrue);
    expect(result.asOf, isNotNull);
  });

  test('parseRulya_liveFixture_returnsBuySellAndTimestamp', () {
    final result = parseRulya(fixture('rulya.html'), now);

    expect(result.rates[Currency.usd]!.buy, 44.60);
    expect(result.rates[Currency.usd]!.sell, 45.40);
    expect(result.rates[Currency.eur]!.buy, 51.00);
    expect(result.rates[Currency.eur]!.sell, 51.80);
    expect(result.asOf, DateTime(2026, 9, 24, 16, 12));
  });

  test('parseLion_liveFixture_returnsBuySellAndDate', () {
    final result = parseLion(fixture('lion.html'), now);

    expect(result.rates[Currency.usd]!.buy, 44.70);
    expect(result.rates[Currency.usd]!.sell, 45.50);
    expect(result.rates[Currency.eur]!.buy, 51.00);
    expect(result.rates[Currency.eur]!.sell, 51.80);
    expect(result.asOf, DateTime(2026, 9, 24));
  });

  test('parseRulya_pageWithoutRates_throwsParseException', () {
    expect(() => parseRulya('<html><body>Maintenance</body></html>', now),
        throwsA(isA<ParseException>()));
  });

  test('parseLion_pageWithoutRates_throwsParseException', () {
    expect(() => parseLion('<html><body>Maintenance</body></html>', now),
        throwsA(isA<ParseException>()));
  });
}
