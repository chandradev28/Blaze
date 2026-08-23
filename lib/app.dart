import 'package:flutter/material.dart';

import 'controllers/blaze_controller.dart';
import 'screens/garage_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';

class BlazeApp extends StatelessWidget {
  const BlazeApp({required this.controller, super.key});

  final BlazeController controller;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6A3D);
    const ink = Color(0xFF08090D);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final active = controller.activeTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Blaze',
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: active.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: orange,
              brightness: Brightness.dark,
              surface: ink,
            ),
            splashFactory: InkSparkle.splashFactory,
            sliderTheme: SliderThemeData(
              activeTrackColor: active.primary,
              thumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.12),
              overlayColor: active.primary.withOpacity(0.16),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: ink.withOpacity(0.94),
              indicatorColor: active.primary.withOpacity(0.20),
              labelTextStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.86),
                ),
              ),
            ),
          ),
          home: _BlazeShell(controller: controller),
        );
      },
    );
  }
}

class _BlazeShell extends StatefulWidget {
  const _BlazeShell({required this.controller});

  final BlazeController controller;

  @override
  State<_BlazeShell> createState() => _BlazeShellState();
}

class _BlazeShellState extends State<_BlazeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(controller: widget.controller),
      GarageScreen(controller: widget.controller),
      HistoryScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Test',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Garage',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
