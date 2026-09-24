import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import '../models/rates.dart';
import 'rates_repository.dart';
import 'widget_publisher.dart';

const _periodicTaskId = 'uah-rates-refresh';
const _periodicTaskName = 'refreshRates';

Future<List<SourceResult>> refreshAndPublish(RatesRepository repository) async {
  final results = await repository.refresh();
  await publishToWidget(results);
  return results;
}

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await refreshAndPublish(RatesRepository());
    return true;
  });
}

@pragma('vm:entry-point')
Future<void> onWidgetInteraction(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri?.host == 'refresh') {
    await refreshAndPublish(RatesRepository());
  }
}

Future<void> setUpBackgroundRefresh() async {
  await HomeWidget.registerInteractivityCallback(onWidgetInteraction);
  await Workmanager().initialize(backgroundDispatcher);
  await Workmanager().registerPeriodicTask(
    _periodicTaskId,
    _periodicTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
