import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:edu_chatbot/data/gemini_response_rating.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/ui/rating_widget.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:image/image.dart' as ui;
import '../data/exam_link.dart';
import '../data/exam_page_image.dart';

class MathViewer extends StatefulWidget {
  const MathViewer(
      {super.key,
      required this.text,
      required this.onShare,
      required this.onRerun,
      required this.selectedImages,
      required this.onExit,
      required this.repository,
      required this.prompt,
      required this.examLink, required this.tokensUsed});

  final String text, prompt;
  final int tokensUsed;
  static const mm = '💙💙💙💙 MathViewer 💙';
  final Function(List<ExamPageImage>) onShare;
  final Function(List<ExamPageImage>) onExit;
  final Function(List<ExamPageImage>) onRerun;
  final List<ExamPageImage> selectedImages;
  final Repository repository;
  final ExamLink examLink;

  @override
  State<MathViewer> createState() => _MathViewerState();
}

class _MathViewerState extends State<MathViewer> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  bool _showRatingBar = true;
  List<ExamPageImage> list = [];

  @override
  void initState() {
    super.initState();
    _clone();
  }

  _share(GeminiResponseRating responseRating) async {
    pp('${MathViewer.mm} ... sharing is caring ...');
    var directory = await getApplicationDocumentsDirectory();

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text("SgelaAI Response"),
          ); // Center
        })); // Page

    //
    if (isValidLaTeXString(responseRating.responseText!)) {
      //todo - write formatted LaTex string to pdf
    } else {
      //todo - write formatted markdown text to pdf
    }
    final result = await Share.shareXFiles([XFile('${directory.path}/response.pdf')],
        text: 'Response from SgelaAI');
    if (result.status == ShareResultStatus.success) {
      pp('${MathViewer.mm} Thank you for sharing the response from SgelaAI!');
    }
  }

  _clone() {
    for (var value in widget.selectedImages) {
      var m = ExamPageImage(value.examLinkId, value.id, value.downloadUrl,
          value.bytes, value.pageIndex, value.mimeType);
      list.add(m);
      pp('${MathViewer.mm} ... _cloned images: ${list.length}');
    }
  }

  bool isRated = false;
  int rating = 0;
  String responseText = '';

  _sendRating(int mRating) async {
    try {
      var examPageImage = list.first;
      var gr = GeminiResponseRating(
          rating: mRating,
          id: DateTime.now().millisecondsSinceEpoch,
          date: DateTime.now().toIso8601String(),
          pageNumber: examPageImage.pageIndex,
          responseText: widget.text,
          tokensUsed: widget.tokensUsed,
          prompt: widget.prompt,
          examLinkId: widget.examLink.id!);
      var res = await widget.repository.addRating(gr);
      pp('💙💙💙💙 GeminiResponseRating sent to backend! id: $res');
      myPrettyJsonPrint(gr.toJson());

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      pp('${MathViewer.mm} ERROR - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var bright = MediaQuery.of(context).platformBrightness;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: Icon(
                  Platform.isAndroid ? Icons.arrow_back : Icons.arrow_back_ios,
                ),
                onPressed: () {
                  // Handle the back button press
                  if (isRated) {
                    Navigator.of(context).pop(rating);
                  } else {
                    showToast(
                        message: 'Please Rate the SgelaAI response',
                        textStyle: myTextStyle(
                            context, Colors.amber, 16, FontWeight.normal),
                        context: context);
                  }
                }),
            title: const Text('Mathematics'),
            actions: [
              PopupMenuButton(
                onSelected: (value) async {
                  switch (value) {
                    case '/share':
                      pp('${MathViewer.mm} ... share required ... images: ${list.length}');
                      widget.onShare(list);
                      break;
                    case '/rating':
                      pp('${MathViewer.mm} ... rating required, will set _showRatingBar true');
                      setState(() {
                        _showRatingBar = true;
                      });
                      break;
                    case '/rerun':
                      pp('${MathViewer.mm} ... rerun required, images: ${list.length}');
                      widget.onRerun(list);
                      Navigator.of(context).pop(rating);
                      break;
                  }
                },
                itemBuilder: (BuildContext bc) {
                  return [
                    PopupMenuItem(
                      value: '/rating',
                      child: Icon(
                        Icons.star,
                        color: bright == Brightness.light
                            ? Colors.black
                            : Colors.yellow,
                      ),
                    ),
                    PopupMenuItem(
                      value: '/share',
                      child: Icon(
                        Icons.share,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    PopupMenuItem(
                      value: '/rerun',
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  ];
                },
              )
            ]),
        body: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Container(
                  width: double.infinity,
                  // height: h,
                  padding: const EdgeInsets.all(2.0),
                  child: Holder(text: getFormattedText()),
                ),
              ),
            ),
            Positioned(
                bottom: 16,
                right: 48,
                child: GeminiRatingWidget(
                  onRating: (rating) {
                    pp('💙💙 Gemini rating: $rating, 💙💙 set _showRatingBar to false');
                    showToast(
                        message: 'Rating saved. Thank you!',
                        textStyle: myTextStyle(
                            context, Colors.greenAccent, 16, FontWeight.normal),
                        context: context);
                    this.rating = rating.round();
                    _sendRating(rating
                        .round()); // Convert the floating-point number to an integer
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        Navigator.of(context).pop(rating);
                      }
                    });
                  },
                  visible: _showRatingBar,
                  color: Colors.blue,
                )),
          ],
        ),
      ),
    );
  }

  String getFormattedText() {
    return widget.text;
  }

  Future<File> convertLatexToImage(
      String latexString, BuildContext context) async {
    final texView = TeXView(
      renderingEngine: const TeXViewRenderingEngine.katex(),
      child: TeXViewDocument(latexString),
    );

    final boundary = GlobalKey();
    final widget = RepaintBoundary(
      key: boundary,
      child: texView,
    );

    final completer = Completer<File>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final renderObject =
          boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject != null) {
        final image = await renderObject.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final file =
            await File('${Directory.systemTemp.path}/latex_image.png').create();
        await file.writeAsBytes(pngBytes);

        completer.complete(file);
      } else {
        completer.completeError(
            Exception('Failed to capture the rendered LaTeX as an image.'));
      }
    });

    return completer.future;
  }

//
}

class Holder extends StatelessWidget {
  const Holder({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    var bright = MediaQuery.of(context).platformBrightness;
    return Card(
      // color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 600,
          child: Column(
            children: [
              Text(
                "SgelaAI Response",
                style: myTextStyle(
                  context,
                  bright == Brightness.light ? Colors.black : Colors.white,
                  24,
                  FontWeight.w900,
                ),
              ),
              gapH16,
              Expanded(
                child: SingleChildScrollView(
                  child: TeXView(
                    style: TeXViewStyle(
                      contentColor: bright == Brightness.light
                          ? Colors.black
                          : Colors.white,
                      backgroundColor: bright == Brightness.light
                          ? Colors.white
                          : Colors.black,
                      padding: const TeXViewPadding.all(8),
                    ),
                    renderingEngine: const TeXViewRenderingEngine.katex(),
                    child: TeXViewColumn(
                      children: [
                        TeXViewDocument(text),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
