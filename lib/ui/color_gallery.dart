import 'dart:async';

import 'package:flutter/material.dart';

import '../util/dark_light_control.dart';
import '../util/functions.dart';
import '../util/prefs.dart';

class ColorGallery extends StatefulWidget {
  const ColorGallery({super.key, required this.prefs, required this.colorWatcher});
  final Prefs prefs;
  final ColorWatcher colorWatcher;
  @override
  ColorGalleryState createState() => ColorGalleryState();
}

class ColorGalleryState extends State<ColorGallery> {
  Color? selectedColor;

  List<Color> colors = [];
  @override
  void initState() {
    super.initState();
    colors = getColors();

  }
  void _setColorIndex(int index) async {
    await widget.prefs.saveColorIndex(index);
    widget.colorWatcher.setColor(index);
  }
  @override
  Widget build(BuildContext context) {

    return SizedBox(height: 300,
      child: GridView.builder(

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3),
          itemCount: colors.length,
          itemBuilder: (_, index){
            var color = colors.elementAt(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = color;
                  _setColorIndex(index);
                });
              },
              child: Container(
                color: color,
                margin: const EdgeInsets.all(8),
                child: selectedColor == color
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                )
                    : null,
              ),
            );
          }),
    );

  }
}

