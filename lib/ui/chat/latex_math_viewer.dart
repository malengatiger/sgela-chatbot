import 'dart:async';
import 'dart:io';

import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/exam_page_image.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:edu_chatbot/ui/chat/ai_rating_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/sgela_util/functions.dart';

import '../../local_util/functions.dart';
import '../exam/exam_link_details.dart';

class SgelaLaTexViewer extends StatefulWidget {
  const SgelaLaTexViewer(
      {super.key,
      required this.text,
      required this.examPageContents, required this.tokensUsed, required this.examLink,
      });

  final String text;
  final int tokensUsed;
  static const mm = '💙💙💙💙 MathViewer 💙';

  final List<ExamPageContent> examPageContents;
  final ExamLink examLink;


  @override
  State<SgelaLaTexViewer> createState() => _SgelaLaTexViewerState();
}

class _SgelaLaTexViewerState extends State<SgelaLaTexViewer> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  bool _showRatingBar = false;
  List<ExamPageImage> list = [];
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
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

  // _share(AIResponseRating responseRating) async {
  //   pp('${LaTexMathViewer.mm} ... sharing is caring ...');
  //   var directory = await getApplicationDocumentsDirectory();
  //
  //   final pdf = pw.Document();
  //   pdf.addPage(pw.Page(
  //       pageFormat: PdfPageFormat.a4,
  //       build: (pw.Context context) {
  //         return pw.Center(
  //           child: pw.Text("SgelaAI Response"),
  //         ); // Center
  //       })); // Page
  //
  //   //
  //   if (isValidLaTeXString(responseRating.responseText!)) {
  //     //todo - write formatted LaTex string to pdf
  //   } else {
  //     //todo - write formatted markdown text to pdf
  //   }
  //   final result = await Share.shareXFiles(
  //       [XFile('${directory.path}/response.pdf')],
  //       text: 'Response from SgelaAI');
  //   if (result.status == ShareResultStatus.success) {
  //     pp('${LaTexMathViewer.mm} Thank you for sharing the response from SgelaAI!');
  //   }
  // }

  bool isRated = false;
  int rating = 0;
  String responseText = '';
  static const mm = '🔵🔵🔵🔵 SgelaLaTexViewer  🔵🔵';

  _sendRating(int mRating) async {
    // try {
    //   var examPageImage = list.first;
    //   var gr = AIResponseRating(
    //       rating: mRating,
    //       id: DateTime.now().millisecondsSinceEpoch,
    //       date: DateTime.now().toIso8601String(),
    //       numberOfPagesInQuery: examPageImage.pageIndex,
    //       responseText: widget.text,
    //       tokensUsed: widget.tokensUsed,
    //       examLinkId: widget.examLink.id!);
    //   var res = await firestoreService.addRating(gr);
    //   pp('💙💙💙💙 GeminiResponseRating sent to backend! id: $res');
    //   myPrettyJsonPrint(gr.toJson());
    //
    //   if (mounted) {
    //     Navigator.of(context).pop();
    //   }
    // } catch (e) {
    //   pp('${LaTexMathViewer.mm} ERROR - $e');
    // }
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
                    pp('${SgelaLaTexViewer.mm} ... share required ... images: ${list.length}');
                  },
                  icon:
                      Icon(Icons.share, color: Theme.of(context).primaryColor)),
            ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(64), child: Column(
            children: [
              gapH8,
              ExamLinkDetails(examLink: widget.examLink, pageNumber: 0),
            ],
          ),),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Container(
                  color: Colors.blue,
                  width: double.infinity,
                  // height: h,
                  padding: const EdgeInsets.all(8.0),
                  child: LaTexCard(text: responseText),
                ),
              ),
            ),
            if (_showRatingBar)  Positioned(
                bottom: 16,
                right: 48,
                child: AIRatingWidget(
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

class LaTexCard extends StatelessWidget {
  const LaTexCard({super.key, required this.text, this.showHeader = true});
  static const mm = '🔵🔵🔵🔵 LaTexCard  🔵🔵';

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
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TeXView(
                        onRenderFinished: (f) {
                          pp('$mm onRenderFinished');
                        },
                        style: TeXViewStyle(
                          contentColor: Colors.white,
                          backgroundColor:
                          Colors.blue[700]!,
                          padding:
                          const TeXViewPadding.all(4),
                        ),
                        renderingEngine:
                        const TeXViewRenderingEngine
                            .katex(),
                        child: TeXViewColumn(
                          children: [
                            TeXViewDocument(
                                text),
                          ],
                        ),
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
