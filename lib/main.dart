import 'package:flutter/material.dart';

import 'screens/rates_screen.dart';
import 'services/background_refresh.dart';
import 'services/rates_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(UahRatesApp(repository: RatesRepository()));
  try {
    await setUpBackgroundRefresh();
  } catch (e) {
    debugPrint('Background refresh setup failed: $e');
  }
}

class UahRatesApp extends StatelessWidget {
  const UahRatesApp({super.key, required this.repository});

  final RatesRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UAH Rates',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: RatesScreen(repository: repository),
    );
  }
}
