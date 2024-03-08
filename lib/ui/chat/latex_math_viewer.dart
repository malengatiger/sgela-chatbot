import 'dart:async';

import 'package:edu_chatbot/ui/chat/ai_rating_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/exam_page_image.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';

import '../../local_util/functions.dart';

class SgelaLaTexViewer extends StatefulWidget {
  const SgelaLaTexViewer({
    super.key,
    required this.text,
    required this.examPageContents,
    required this.tokensUsed,
    required this.examLink,
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

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: LaTexCard(text: responseText),
          ),
        ),
        if (_showRatingBar)
          Positioned(
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
    return SizedBox(
      height: 600,
      child: Column(
        children: [

          gapH16,
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TeXView(
                    onRenderFinished: (f) {
                      pp('$mm onRenderFinished');
                    },
                    style: TeXViewStyle(
                      contentColor: Colors.white,
                      backgroundColor: Colors.blue[700]!,
                      padding: const TeXViewPadding.all(4),
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
    );
  }
}
