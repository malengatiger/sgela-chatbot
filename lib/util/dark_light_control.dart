import 'dart:async';

import 'package:edu_chatbot/util/prefs.dart';

class DarkLightControl {
  static final StreamController<int> _streamController = StreamController.broadcast();
  static Stream<int> get darkLightStream => _streamController.stream;

  static setDarkMode() {
    _streamController.sink.add(1);
    Prefs.saveMode(1);
  }
  static setLightMode() {
    _streamController.sink.add(0);
    Prefs.saveMode(0);
  }
}
