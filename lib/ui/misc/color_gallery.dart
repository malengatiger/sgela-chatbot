import 'dart:async';

import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:flutter/material.dart';
import 'package:sgela_services/sgela_util/dark_light_control.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

import '../../local_util/functions.dart';


class ColorGallery extends StatefulWidget {
  const ColorGallery(
      {super.key, required this.prefs, required this.colorWatcher});

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
    pp('colors available: ${colors.length}');
  }

  void _setColorIndex(int index)  {
    widget.prefs.saveColorIndex(index);
    widget.colorWatcher.setColor(index);
    Future.delayed(const Duration(milliseconds: 1000), (){
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
        appBar: AppBar(
            title:  Text('Primary Colour',
              style: myTextStyle(context, Theme.of(context).primaryColor,
                  18, FontWeight.bold),),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 8,
                child: Column(
                  children: [
                    gapH16,
                     Text('Tap to select your app\'s colour',
                      style: myTextStyle(context, Theme.of(context).primaryColor,
                          16, FontWeight.bold),),
                    gapH16,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4),
                            itemCount: colors.length,
                            itemBuilder: (_, index) {
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
                      ),
                    ),
                    const SponsoredBy(),
                  ],
                ),
              ),
            ),
          ],
        )
    ),
    );
  }
}

