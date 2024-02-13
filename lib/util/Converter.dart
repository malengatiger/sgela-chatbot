import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:markdown/markdown.dart';

class Converter {
  static String convertMarkdownToHtml(String text) {
    var html = markdownToHtml(text);
    return html;
  }

  static List<File> convertUint8ListToFiles(List<Uint8List> uint8List) {
    List<File> fileList = [];

    for (Uint8List bytes in uint8List) {
      File file = File(
          '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png');
      file.writeAsBytesSync(bytes);
      fileList.add(file);
    }
    return fileList;
  }
  static List<XFile> convertFilesToXFiles(List<File> files) {
    List<XFile> xFiles = [];
    for (var file in files) {
      xFiles.add(XFile(file.path));
    }
    return xFiles;
  }

}
