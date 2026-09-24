import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/rates.dart';
import '../services/background_refresh.dart';
import '../services/rates_repository.dart';

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
    setState(() => _loading = true);
    final results = await refreshAndPublish(widget.repository);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UAH Rates'),
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final result in _results) ...[
              _SourceCard(result: result),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.result});

  final SourceResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = result.data;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(result.source.label, style: theme.textTheme.titleLarge),
                const Spacer(),
                if (result.isStale)
                  Icon(Icons.cloud_off, size: 18, color: theme.colorScheme.error),
              ],
            ),
            const SizedBox(height: 4),
            Text(_subtitle(data), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (data == null)
              Text(result.isStale ? 'Could not load rates' : 'Loading…')
            else
              _RatesTable(data: data),
          ],
        ),
      ),
    );
  }

  String _subtitle(SourceRates? data) {
    final asOf = data?.asOf;
    if (asOf == null) return result.source.url;
    final hasTime = asOf.hour != 0 || asOf.minute != 0;
    return 'as of ${DateFormat(hasTime ? 'dd.MM.yyyy HH:mm' : 'dd.MM.yyyy').format(asOf)}';
  }
}

class _RatesTable extends StatelessWidget {
  const _RatesTable({required this.data});

  final SourceRates data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOfficial = data.rates.values.every((r) => r.isOfficial);
    final header = theme.textTheme.labelMedium;
    final value = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Table(
      columnWidths: const {0: FixedColumnWidth(56)},
      children: [
        TableRow(children: [
          const SizedBox.shrink(),
          if (isOfficial)
            Text('Official', style: header)
          else ...[
            Text('Buy', style: header),
            Text('Sell', style: header),
          ],
        ]),
        for (final currency in Currency.values)
          if (data.rates[currency] case final rate?)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(currency.name.toUpperCase(), style: value),
              ),
              if (isOfficial)
                _cell(rate.buy, value, 4)
              else ...[
                _cell(rate.buy, value, 2),
                _cell(rate.sell, value, 2),
              ],
            ]),
      ],
    );
  }

  Widget _cell(double number, TextStyle? style, int digits) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(number.toStringAsFixed(digits), style: style),
      );
}
