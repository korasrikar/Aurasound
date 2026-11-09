import 'package:flutter/widgets.dart';

import 'app.dart';
import 'player/just_audio_engine.dart';
import 'player/player_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PlayerController(engine: JustAudioEngine());
  runApp(AuraSoundApp(controller: controller));
}
