import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'app.dart';
import 'controllers/blaze_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugRepaintRainbowEnabled = false;
  final controller = BlazeController();
  await controller.hydrate();
  runApp(BlazeApp(controller: controller));
}
