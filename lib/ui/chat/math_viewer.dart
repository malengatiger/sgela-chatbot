import 'dart:async';
import 'dart:io';

import 'package:edu_chatbot/data/gemini_response_rating.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/ui/chat/rating_widget.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/exam_link.dart';
import '../../data/exam_page_image.dart';

class MathViewer extends StatefulWidget {
  const MathViewer(
      {super.key,
      required this.text,
      required this.examPageImage,
      required this.repository,
      required this.prompt,
      required this.examLink,
      required this.tokensUsed,
      this.showHeader});

  final String text, prompt;
  final int tokensUsed;
  static const mm = '💙💙💙💙 MathViewer 💙';

  final ExamPageImage examPageImage;
  final FirestoreService repository;
  final ExamLink examLink;

  final bool? showHeader;

  @override
  State<MathViewer> createState() => _MathViewerState();
}

class _MathViewerState extends State<MathViewer> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  bool _showRatingBar = false;
  List<ExamPageImage> list = [];

  @override
  void initState() {
    super.initState();
    replaceMarkdownTags();
  }

  replaceMarkdownTags() {
    responseText = widget.text;
    responseText = responseText.replaceAll('##', '\n').replaceAll('#', '\n');
    responseText = responseText.replaceAll('Blank Line', '\n');
    setState(() {});
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
    final result = await Share.shareXFiles(
        [XFile('${directory.path}/response.pdf')],
        text: 'Response from SgelaAI');
    if (result.status == ShareResultStatus.success) {
      pp('${MathViewer.mm} Thank you for sharing the response from SgelaAI!');
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
                    setState(() {
                      _showRatingBar = true;
                    });
                  }
                }),
            actions: [
              IconButton(
                  onPressed: () {
                    pp('${MathViewer.mm} ... share required ... images: ${list.length}');
                  },
                  icon:
                      Icon(Icons.share, color: Theme.of(context).primaryColor)),
            ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(64), child: Column(
            children: [
              gapH8,
              Text(
                '${widget.examLink.title}',
                style: myTextStyle(
                    context, Theme.of(context).primaryColor, 16, FontWeight.w900),
              ),
              Text(
                '${widget.examLink.subject!.title}',
                style: myTextStyle(
                    context, Theme.of(context).primaryColor, 14, FontWeight.normal),
              ),
              Text(
                '${widget.examLink.documentTitle}',
                style: myTextStyle(
                    context, Theme.of(context).primaryColor, 14, FontWeight.normal),
              ),
              Text(
                '${widget.examPageImage.pageIndex}',
                style: myTextStyle(
                    context, Theme.of(context).primaryColor, 18, FontWeight.w900),
              ),
            ],
          ),),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Container(
                  width: double.infinity,
                  // height: h,
                  padding: const EdgeInsets.all(8.0),
                  child: LaTexViewer(text: responseText),
                ),
              ),
            ),
            if (_showRatingBar)  Positioned(
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
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        Navigator.of(context).pop(rating);
                      }
                    });
                  },
                  visible: true,
                )),
          ],
        ),
      ),
    );
  }
}

class LaTexViewer extends StatelessWidget {
  const LaTexViewer({super.key, required this.text, this.showHeader = true});

  final String text;
  final bool? showHeader;

  @override
  Widget build(BuildContext context) {
    var bright = MediaQuery.of(context).platformBrightness;
    return Card(
      // color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 600,
        child: Column(
          children: [
            gapH8,
            showHeader!
                ? Text(
                    "SgelaAI Response",
                    style: myTextStyle(
                      context,
                      Theme.of(context).primaryColor,
                      24,
                      FontWeight.w900,
                    ),
                  )
                : gapW4,
            gapH16,
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(height: 600,
                    child: TeXView(
                      style: TeXViewStyle(
                        contentColor: Colors.white,
                        backgroundColor: Colors.transparent,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
