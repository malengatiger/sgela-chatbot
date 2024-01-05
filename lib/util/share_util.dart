import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/gemini_response_rating.dart';
import 'functions.dart';

class ShareUtil {
  static const mm = 'ShareUtil';

  _share(GeminiResponseRating responseRating, BuildContext context) async {
    const mm = 'ShareUtil';
    pp('$mm ... sharing is caring ...');
    var directory = await getApplicationDocumentsDirectory();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text("SgelaAI Response"),
          );
        },
      ),
    );

    if (isValidLaTeXString(responseRating.responseText!)) {
      // Render LaTeX string as an image
      final texView = TeXView(
        renderingEngine: const TeXViewRenderingEngine.katex(),
        child: TeXViewDocument(responseRating.responseText!),
      );

      final boundary = RepaintBoundary(
        child: texView,
      );
      final renderObject = boundary.createRenderObject(context);
      const constraints = pw.BoxConstraints(
        minWidth: 0.0,
        minHeight: 0.0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      );

      renderObject.layout(constraints as Constraints);
      final image = await renderObject.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final imageProvider = pw.MemoryImage(pngBytes);
      final imageWidget = pw.Image(imageProvider);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                child: imageWidget,
              ),
            );
          },
        ),
      );
    } else {
      // Render Markdown string as an image
      final markdownWidget = Markdown(data: responseRating.responseText!);
      final boundary = RepaintBoundary(
        child: markdownWidget,
      );

      final renderObject = boundary.createRenderObject(context);
      const constraints = pw.BoxConstraints(
        minWidth: 0.0,
        minHeight: 0.0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      );

      renderObject.layout(constraints as Constraints);
      final image = await renderObject.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final imageProvider = pw.MemoryImage(pngBytes);
      final imageWidget = pw.Image(imageProvider);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                child: imageWidget,
              ),
            );
          },
        ),
      );
    }

    final file = File('${directory.path}/response.pdf');
    await file.writeAsBytes(await pdf.save());
    XFile xFile = XFile.fromData(file.readAsBytesSync());
    final result =
        await Share.shareXFiles([xFile], text: 'Response from SgelaAI');
    if (result.status == ShareResultStatus.success) {
      pp('$mm Thank you for sharing the response from SgelaAI!');
    }
  }
}
