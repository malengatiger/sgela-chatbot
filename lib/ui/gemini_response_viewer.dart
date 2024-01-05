import 'dart:io';

import 'package:edu_chatbot/data/exam_page_image.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/ui/rating_widget.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'markdown_widget.dart' as md;
import '../data/exam_link.dart';
import '../data/gemini/gemini_response.dart';
import '../data/gemini_response_rating.dart';

class GeminiResponseViewer extends StatefulWidget {
  const GeminiResponseViewer(
      {super.key,
      required this.examLink,
      required this.geminiResponse,
      required this.repository,
      required this.prompt,
      required this.examPageImage});

  final ExamLink examLink;
  final MyGeminiResponse geminiResponse;
  final Repository repository;
  final String prompt;
  final ExamPageImage examPageImage;

  @override
  State<GeminiResponseViewer> createState() => _GeminiResponseViewerState();
}

class _GeminiResponseViewerState extends State<GeminiResponseViewer> {
  static const mm = '🍐🍐🍐🍐 GeminiResponseViewer 🍐';

  String getResponseString() {
    var sb = StringBuffer();
    widget.geminiResponse.candidates?.forEach((candidate) {
      candidate.content?.parts?.forEach((parts) {
        sb.write(parts.text ?? '');
        sb.write('\n');
      });
    });
    return sb.toString();
  }

  final bool _showRatingBar = true;

  _sendRating(int mRating) async {
    try {
      var gr = GeminiResponseRating(
          rating: mRating,
          date: DateTime.now().toIso8601String(),
          pageNumber: widget.examPageImage.id,
          responseText: getResponseString(),
          prompt: widget.prompt, examLinkId: widget.examLink.id!);

      var res = await widget.repository.addRating(gr);
      pp('$mm 💙💙💙💙 GeminiResponseRating sent to backend!  🍎🍎🍎response: $res');
    } catch (e) {
      pp('$mm ERROR - $e');
    }
  }

  bool isRated = false;
  int ratingUpdated = 0;

  @override
  Widget build(BuildContext context) {
    var bright = MediaQuery.of(context).platformBrightness;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "${widget.examLink.title}",
            style: myTextStyle(context, Colors.black, 14, FontWeight.bold),
          ),
          leading: IconButton(
              icon: Icon(
                Platform.isAndroid ? Icons.arrow_back : Icons.arrow_back_ios,
              ),
              onPressed: () {
                // Handle the back button press
                if (isRated) {
                  Navigator.of(context).pop(ratingUpdated);
                } else {
                  showToast(
                      message: 'Please Rate the SgelaAI response',
                      textStyle: myTextStyle(
                          context, Colors.amber, 16, FontWeight.normal),
                      context: context);
                }
              }),
          actions: [
            IconButton(
                onPressed: () {
                  pp('$mm ... share pressed');
                },
                icon: const Icon(Icons.share))
          ],
        ),
        // backgroundColor: bright == Brightness.light?Colors.brown.shade100:Colors.black26,
        body: Stack(
          children: [
            Column(
              children: [
                gapH8,
                Card(
                  elevation: 8,
                  // color: Theme.of(context).primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 48.0, right: 48.0, top: 8.0, bottom: 8.0),
                    child: Text('SgelaAI Response',
                        style: myTextStyle(
                            context,
                            bright == Brightness.dark?Colors.black:Theme.of(context).primaryColor,
                            20,
                            FontWeight.w900)),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                              child: md.MarkdownWidget(
                                  text: getResponseString())),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _showRatingBar
                ? Positioned(
                    bottom: 12,
                    left: 12, right:12,
                    child: Center(
                      child: GeminiRatingWidget(
                          onRating: (mRating) {
                            if (mounted) {
                              setState(() {
                                isRated = true;
                                ratingUpdated = mRating.round();
                              });
                            }
                            _sendRating(mRating.round());
                            Navigator.of(context).pop();
                          },
                          visible: true),
                    ),
                  )
                : gapW8,
          ],
        ),
      ),
    );
  }
}
