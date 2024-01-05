import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import 'functions.dart';

class WidgetToImageConverter {

  static  Future<File> convertWidgetToImage(GlobalKey<ScaffoldState> scaffoldKey) async {
    RenderRepaintBoundary boundary = scaffoldKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    File file = await File('${Directory.systemTemp.path}/widget_image.png').create();
    await file.writeAsBytes(pngBytes!);
    pp('🍎🍎WidgetToImageConverter: image file created: 🍎${await file.length()} bytes 🍎');
    return file;
  }

}