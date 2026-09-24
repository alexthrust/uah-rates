import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../models/rates.dart';

class ParseException implements Exception {
  ParseException(this.message);

  final String message;

  @override
  String toString() => 'ParseException: $message';
}

SourceRates parseNbu(String body, DateTime fetchedAt) {
  final entries = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
  final rates = <Currency, Rate>{};
  DateTime? asOf;
  for (final entry in entries) {
    final currency = _currencyFromCode(entry['cc'] as String?);
    if (currency == null) continue;
    rates[currency] = Rate.official((entry['rate'] as num).toDouble());
    asOf ??= _parseDate(entry['exchangedate'] as String?);
  }
  _requireAll(rates, RateSource.nbu);
  return SourceRates(
    source: RateSource.nbu,
    rates: rates,
    asOf: asOf,
    fetchedAt: fetchedAt,
  );
}

SourceRates parseRulya(String body, DateTime fetchedAt) {
  final document = html.parse(body);
  final rates = <Currency, Rate>{};
  for (final row in document.querySelectorAll('tr')) {
    final cells = row.querySelectorAll('h3').map((e) => e.text.trim()).toList();
    if (cells.length < 3) continue;
    final currency = _currencyFromCode(cells[0]);
    if (currency == null || rates.containsKey(currency)) continue;
    rates[currency] = Rate(buy: _number(cells[1]), sell: _number(cells[2]));
  }
  _requireAll(rates, RateSource.rulya);

  final stamp = RegExp(r'станом на\s*\[\s*(\d{1,2}):(\d{2})\s*\]\s*(\d{2}\.\d{2}\.\d{4})')
      .firstMatch(document.body?.text ?? '');
  final date = _parseDate(stamp?.group(3));
  final asOf = date == null
      ? null
      : DateTime(date.year, date.month, date.day,
          int.parse(stamp!.group(1)!), int.parse(stamp.group(2)!));

  return SourceRates(
    source: RateSource.rulya,
    rates: rates,
    asOf: asOf,
    fetchedAt: fetchedAt,
  );
}

SourceRates parseLion(String body, DateTime fetchedAt) {
  final document = html.parse(body);
  final rates = <Currency, Rate>{};
  for (final row in document.querySelectorAll('tr')) {
    final currency = _lionCurrency(row);
    if (currency == null || rates.containsKey(currency)) continue;
    final values = row.querySelectorAll('td.white').map((e) => e.text.trim()).toList();
    if (values.length < 2) continue;
    rates[currency] = Rate(buy: _number(values[0]), sell: _number(values[1]));
  }
  _requireAll(rates, RateSource.lion);

  return SourceRates(
    source: RateSource.lion,
    rates: rates,
    asOf: document
        .querySelectorAll('div.date')
        .map((e) => _parseDate(e.text))
        .firstWhere((d) => d != null, orElse: () => null),
    fetchedAt: fetchedAt,
  );
}

Currency? _lionCurrency(Element row) {
  final src = row.querySelector('td.valuta img')?.attributes['src'] ?? '';
  final file = src.split('/').last.toLowerCase();
  return switch (file) {
    'usd.gif' => Currency.usd,
    'eur.gif' => Currency.eur,
    _ => null,
  };
}

Currency? _currencyFromCode(String? code) => switch (code?.toUpperCase()) {
      'USD' => Currency.usd,
      'EUR' => Currency.eur,
      _ => null,
    };

double _number(String text) {
  final value = double.tryParse(text.replaceAll(',', '.').trim());
  if (value == null || value <= 0) {
    throw ParseException('Not a rate: "$text"');
  }
  return value;
}

DateTime? _parseDate(String? text) {
  final match = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})').firstMatch(text ?? '');
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
  );
}

void _requireAll(Map<Currency, Rate> rates, RateSource source) {
  final missing = Currency.values.where((c) => !rates.containsKey(c));
  if (missing.isNotEmpty) {
    throw ParseException(
        '${source.label}: missing ${missing.map((c) => c.name.toUpperCase()).join(', ')}');
  }
}
