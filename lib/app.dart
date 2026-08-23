import 'package:flutter/material.dart';

import 'controllers/blaze_controller.dart';
import 'screens/home_screen.dart';

class BlazeApp extends StatelessWidget {
  const BlazeApp({required this.controller, super.key});

  final BlazeController controller;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6A3D);
    const ink = Colors.black;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blaze',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.dark,
          surface: ink,
        ),
        splashFactory: InkSparkle.splashFactory,
        sliderTheme: SliderThemeData(
          activeTrackColor: orange,
          thumbColor: Colors.white,
          inactiveTrackColor: Colors.white.withOpacity(0.12),
          overlayColor: orange.withOpacity(0.16),
        ),
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
