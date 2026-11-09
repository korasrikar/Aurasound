import 'package:flutter/material.dart';

import 'data/demo_catalog.dart';
import 'features/home/home_screen.dart';
import 'player/player_controller.dart';

class AuraSoundApp extends StatelessWidget {
  const AuraSoundApp({super.key, required this.controller});

  final PlayerController controller;

  static const _seed = Color(0xFF6C4CF1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraSound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller, tracks: demoTracks),
    );
  }
}
