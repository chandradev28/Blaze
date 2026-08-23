import 'package:flutter/material.dart';

import 'app.dart';
import 'controllers/blaze_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = BlazeController();
  await controller.hydrate();
  runApp(BlazeApp(controller: controller));
}
