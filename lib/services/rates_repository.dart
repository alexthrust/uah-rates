import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rates.dart';
import '../sources/parsers.dart';

class RatesRepository {
  RatesRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);
  static const _cachePrefix = 'rates_';

  final http.Client _client;

  Future<List<SourceResult>> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return [
      for (final source in RateSource.values)
        SourceResult(source: source, data: _readCache(prefs, source)),
    ];
  }

  Future<List<SourceResult>> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    return Future.wait(RateSource.values.map((s) => _refreshSource(prefs, s)));
  }

  Future<SourceResult> _refreshSource(SharedPreferences prefs, RateSource source) async {
    try {
      final data = await _fetch(source);
      await prefs.setString(_cachePrefix + source.name, jsonEncode(data.toJson()));
      return SourceResult(source: source, data: data);
    } catch (_) {
      return SourceResult(source: source, data: _readCache(prefs, source), isStale: true);
    }
  }

  Future<SourceRates> _fetch(RateSource source) async {
    final response = await _client
        .get(Uri.parse(source.url), headers: {'User-Agent': 'Mozilla/5.0 (Android) uah-rates'})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', response.request?.url);
    }
    final body = utf8.decode(response.bodyBytes, allowMalformed: true).replaceFirst('﻿', '');
    final now = DateTime.now();
    return switch (source) {
      RateSource.nbu => parseNbu(body, now),
      RateSource.rulya => parseRulya(body, now),
      RateSource.lion => parseLion(body, now),
    };
  }

  SourceRates? _readCache(SharedPreferences prefs, RateSource source) {
    final raw = prefs.getString(_cachePrefix + source.name);
    if (raw == null) return null;
    try {
      return SourceRates.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
