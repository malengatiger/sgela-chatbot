import 'dart:async';

import 'package:edu_chatbot/util/prefs.dart';

import 'functions.dart';

class DarkLightControl {
  DarkLightControl(this.prefs);

   final StreamController<ModeAndColor> _streamController =
      StreamController.broadcast();

   Stream<ModeAndColor> get darkLightStream => _streamController.stream;
  final Prefs prefs;

  setDarkMode() async {
    int colorIndex = await prefs.getColorIndex();
    var mc = ModeAndColor(DARK, colorIndex);
    _streamController.sink.add(mc);
    prefs.saveMode(DARK);
  }

  setLightMode() async {
    int colorIndex = await prefs.getColorIndex();
    var mc = ModeAndColor(LIGHT, colorIndex);
    _streamController.sink.add(mc);
    prefs.saveMode(LIGHT);
  }
}

class ColorWatcher {
  final DarkLightControl darkLightControl;
  final Prefs prefs;
  final StreamController<int> _streamController = StreamController.broadcast();

  ColorWatcher(this.darkLightControl, this.prefs);

  Stream<int> get colorStream => _streamController.stream;

  void setColor(int colorIndex) async {
    _streamController.sink.add(colorIndex);
    int mode = await prefs.getMode();
    await prefs.saveColorIndex(colorIndex);

    if (mode == LIGHT) {
      darkLightControl.setLightMode();
    } else {
      darkLightControl.setDarkMode();
    }
    pp('ColorWatcher: color has been set: $colorIndex');
  }
}

class ModeAndColor {
  late int mode, colorIndex;

  ModeAndColor(this.mode, this.colorIndex);
}

const DARK = 1;
const LIGHT = 0;
