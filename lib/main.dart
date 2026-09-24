import 'package:flutter/material.dart';

import 'screens/rates_screen.dart';
import 'services/rates_repository.dart';

void main() {
  runApp(UahRatesApp(repository: RatesRepository()));
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
