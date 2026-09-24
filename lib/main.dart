import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/rates_screen.dart';
import 'services/background_refresh.dart';
import 'services/rates_repository.dart';

const _seedColor = Color(0xFF0B7A6F);

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
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        title: 'UAH Rates',
        debugShowCheckedModeBanner: false,
        theme: _theme(lightDynamic ?? ColorScheme.fromSeed(seedColor: _seedColor)),
        darkTheme: _theme(
          darkDynamic ??
              ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
        ),
        home: RatesScreen(repository: repository),
      ),
    );
  }

  ThemeData _theme(ColorScheme scheme) => ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: scheme.surface,
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      );
}
