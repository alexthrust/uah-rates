import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/rates.dart';
import '../services/background_refresh.dart';
import '../services/rates_repository.dart';

const _tabular = [FontFeature.tabularFigures()];

extension on Currency {
  String get code => name.toUpperCase();

  String get flag => switch (this) {
        Currency.usd => '🇺🇸',
        Currency.eur => '🇪🇺',
      };
}

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key, required this.repository});

  final RatesRepository repository;

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  List<SourceResult> _results = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cached = await widget.repository.loadCached();
    if (mounted) setState(() => _results = cached);
    await _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await refreshAndPublish(widget.repository);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  SourceResult? _resultFor(RateSource source) =>
      _results.where((r) => r.source == source).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final offices = _results.where((r) => r.source != RateSource.nbu).toList();
    final best = BestRates.from(offices);
    final nbu = _resultFor(RateSource.nbu);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('UAH Rates'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: _refresh,
                        ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.list(
                children: [
                  _SectionHeader(
                    title: 'Official rate',
                    trailing: _officialDate(nbu),
                    isStale: nbu?.isStale ?? false,
                  ),
                  _OfficialRates(result: nbu),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'Exchange offices'),
                  for (final office in offices) ...[
                    _OfficeCard(result: office, best: best),
                    const SizedBox(height: 12),
                  ],
                  _UpdatedFooter(results: _results),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _officialDate(SourceResult? nbu) {
    final asOf = nbu?.data?.asOf;
    return asOf == null ? null : 'NBU · ${DateFormat('d MMM').format(asOf)}';
  }
}

class BestRates {
  const BestRates(this.buy, this.sell);

  factory BestRates.from(List<SourceResult> offices) {
    final buy = <Currency, double>{};
    final sell = <Currency, double>{};
    for (final currency in Currency.values) {
      final rates = offices.map((o) => o.data?.rates[currency]).whereType<Rate>().toList();
      if (rates.length < 2) continue;
      final buys = rates.map((r) => r.buy).toSet();
      final sells = rates.map((r) => r.sell).toSet();
      if (buys.length > 1) buy[currency] = buys.reduce((a, b) => a > b ? a : b);
      if (sells.length > 1) sell[currency] = sells.reduce((a, b) => a < b ? a : b);
    }
    return BestRates(buy, sell);
  }

  final Map<Currency, double> buy;
  final Map<Currency, double> sell;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.isStale = false});

  final String title;
  final String? trailing;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (isStale) ...[
            Icon(Icons.cloud_off_rounded, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 6),
          ],
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _OfficialRates extends StatelessWidget {
  const _OfficialRates({required this.result});

  final SourceResult? result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final currency in Currency.values) ...[
          if (currency != Currency.values.first) const SizedBox(width: 12),
          Expanded(
            child: _OfficialTile(
              currency: currency,
              value: result?.data?.rates[currency]?.buy,
              failed: result?.isStale == true && result?.data == null,
            ),
          ),
        ],
      ],
    );
  }
}

class _OfficialTile extends StatelessWidget {
  const _OfficialTile({required this.currency, required this.value, required this.failed});

  final Currency currency;
  final double? value;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = value?.toStringAsFixed(4);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Flag(currency: currency, background: scheme.surface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                currency.code,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (text == null)
            Text(
              failed ? 'Unavailable' : '—',
              style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onPrimaryContainer),
            )
          else
            Text.rich(
              TextSpan(children: [
                TextSpan(text: text.substring(0, text.length - 2)),
                TextSpan(
                  text: text.substring(text.length - 2),
                  style: TextStyle(
                    fontSize: 18,
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.55),
                  ),
                ),
              ]),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontFeatures: _tabular,
              ),
            ),
        ],
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({required this.result, required this.best});

  final SourceResult result;
  final BestRates best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = result.data;
    final muted = theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.secondaryContainer,
                  child: Text(
                    result.source.label.substring(0, 1),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.source.label,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (result.isStale) ...[
                  Icon(Icons.cloud_off_rounded, size: 16, color: scheme.error),
                  const SizedBox(width: 6),
                ],
                if (_asOfLabel(data) case final label?) _Chip(label: label),
              ],
            ),
            const SizedBox(height: 12),
            if (data == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(result.isStale ? 'Could not load rates' : 'Loading…', style: muted),
              )
            else ...[
              Row(
                children: [
                  const Expanded(flex: 4, child: SizedBox.shrink()),
                  Expanded(flex: 3, child: Text('Buy', style: muted, textAlign: TextAlign.end)),
                  Expanded(flex: 3, child: Text('Sell', style: muted, textAlign: TextAlign.end)),
                ],
              ),
              for (final currency in Currency.values)
                if (data.rates[currency] case final rate?)
                  _OfficeRow(
                    currency: currency,
                    rate: rate,
                    bestBuy: best.buy[currency] == rate.buy,
                    bestSell: best.sell[currency] == rate.sell,
                  ),
            ],
          ],
        ),
      ),
    );
  }

  String? _asOfLabel(SourceRates? data) {
    final asOf = data?.asOf;
    if (asOf == null) return null;
    final hasTime = asOf.hour != 0 || asOf.minute != 0;
    return DateFormat(hasTime ? 'HH:mm' : 'd MMM').format(asOf);
  }
}

class _OfficeRow extends StatelessWidget {
  const _OfficeRow({
    required this.currency,
    required this.rate,
    required this.bestBuy,
    required this.bestSell,
  });

  final Currency currency;
  final Rate rate;
  final bool bestBuy;
  final bool bestSell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _Flag(currency: currency, background: theme.colorScheme.surfaceContainerHighest),
                const SizedBox(width: 10),
                Text(
                  currency.code,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: _RateValue(value: rate.buy, isBest: bestBuy)),
          Expanded(flex: 3, child: _RateValue(value: rate.sell, isBest: bestSell)),
        ],
      ),
    );
  }
}

class _RateValue extends StatelessWidget {
  const _RateValue({required this.value, required this.isBest});

  final double value;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
      color: isBest ? scheme.onTertiaryContainer : scheme.onSurface,
      fontFeatures: _tabular,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: isBest
            ? BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Text(value.toStringAsFixed(2), style: style),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.currency, required this.background});

  final Currency currency;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(currency.flag, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatedFooter extends StatelessWidget {
  const _UpdatedFooter({required this.results});

  final List<SourceResult> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fetched = results.map((r) => r.data?.fetchedAt).whereType<DateTime>().toList()
      ..sort();
    if (fetched.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Updated ${DateFormat('HH:mm').format(fetched.last)} · Highlighted: best rate among offices',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
