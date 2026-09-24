enum Currency { usd, eur }

enum RateSource {
  nbu('NBU', 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json'),
  rulya('Rulya', 'https://rulya-bank.com.ua'),
  lion('Lion', 'https://lion-kurs.rv.ua');

  const RateSource(this.label, this.url);

  final String label;
  final String url;
}

class Rate {
  const Rate({required this.buy, required this.sell});

  const Rate.official(double value) : buy = value, sell = value;

  final double buy;
  final double sell;

  bool get isOfficial => buy == sell;

  Map<String, dynamic> toJson() => {'buy': buy, 'sell': sell};

  factory Rate.fromJson(Map<String, dynamic> json) => Rate(
        buy: (json['buy'] as num).toDouble(),
        sell: (json['sell'] as num).toDouble(),
      );
}

class SourceRates {
  const SourceRates({
    required this.source,
    required this.rates,
    required this.asOf,
    required this.fetchedAt,
  });

  final RateSource source;
  final Map<Currency, Rate> rates;
  final DateTime? asOf;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'rates': {for (final e in rates.entries) e.key.name: e.value.toJson()},
        'asOf': asOf?.toIso8601String(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory SourceRates.fromJson(Map<String, dynamic> json) => SourceRates(
        source: RateSource.values.byName(json['source'] as String),
        rates: {
          for (final e in (json['rates'] as Map<String, dynamic>).entries)
            Currency.values.byName(e.key):
                Rate.fromJson(e.value as Map<String, dynamic>),
        },
        asOf: json['asOf'] == null ? null : DateTime.parse(json['asOf'] as String),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
}

class SourceResult {
  const SourceResult({required this.source, this.data, this.isStale = false});

  final RateSource source;
  final SourceRates? data;
  final bool isStale;
}
