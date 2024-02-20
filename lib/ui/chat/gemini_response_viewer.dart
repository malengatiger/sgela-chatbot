import 'dart:io';

import 'package:edu_chatbot/ui/chat/ai_rating_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/image_file_util.dart';
import 'package:share_plus/share_plus.dart';

import '../../local_util/functions.dart';
import 'sgela_markdown_widget.dart' as md;

class GeminiResponseViewer extends StatefulWidget {
  const GeminiResponseViewer(
      {super.key,
      required this.examLink,
      required this.geminiResponse,
      required this.prompt,
      required this.examPageContent,
      required this.tokensUsed});

  final ExamLink examLink;
  final String geminiResponse;
  final String prompt;
  final ExamPageContent examPageContent;
  final int tokensUsed;

  @override
  State<GeminiResponseViewer> createState() => _GeminiResponseViewerState();
}

class _GeminiResponseViewerState extends State<GeminiResponseViewer> {
  static const mm = '🍐🍐🍐🍐 GeminiResponseViewer 🍐';

  bool _showRatingBar = false;
  String responseText = '';
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();


  @override
  void initState() {
    super.initState();
    removeCenterTags(widget.geminiResponse);
  }

  removeCenterTags(String text) {
    responseText = text.replaceAll('<center>', '').replaceAll('</center>', '');
    setState(() {});
  }

  _sendRating(int mRating) async {
    // try {
    //   var gr = AIResponseRating(
    //       rating: mRating,
    //       id: DateTime.now().millisecondsSinceEpoch,
    //       date: DateTime.now().toIso8601String(),
    //       numberOfPagesInQuery: widget.examPageContent.pageIndex,
    //       tokensUsed: widget.tokensUsed,
    //       examLinkId: widget.examLink.id!);
    //
    //   var res = await firestoreService.addRating(gr);
    //   pp('$mm 💙💙💙💙 GeminiResponseRating sent to backend!  🍎🍎🍎response: $res');
    // } catch (e) {
    //   pp('$mm ERROR - $e');
    // }
  }

  _share() async {
    StringBuffer sb = StringBuffer();
    sb.write('# ${widget.examLink.subject!.title}\n');
    sb.write('## ${widget.examLink.title}\n');
    sb.write('### **${widget.examLink.documentTitle}**\n\n');
    sb.write('$responseText\n');

    File mdFile = await ImageFileUtil.getFileFromString(sb.toString(),
        'response_${widget.examLink.id}_${widget.examPageContent.pageIndex}.md');
    var xFile = XFile(mdFile.path);
    pp('$mm XFile created: '
        '${await xFile.length()} bytes - path: ${xFile.path}');

    var shareResult = await Share.shareXFiles([xFile]);
    pp('$mm shareResult.status.name: ${shareResult.status.name}');
  }

  bool isRated = false;
  int ratingUpdated = 0;

  @override
  Widget build(BuildContext context) {
    var bright = MediaQuery.of(context).platformBrightness;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                "${widget.examLink.subject!.title}",
                style: myTextStyle(context, Theme.of(context).primaryColor, 14,
                    FontWeight.bold),
              ),
            ],
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
                  setState(() {
                    _showRatingBar = true;
                  });
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
                  _share();
                },
                icon: Icon(Icons.share, color: Theme.of(context).primaryColor))
          ],
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Column(
                children: [
                  Text(
                    "${widget.examLink.title}",
                    style: myTextStyle(context, Theme.of(context).primaryColor,
                        13, FontWeight.normal),
                  ),
                  Text(
                    "${widget.examLink.documentTitle}",
                    style: myTextStyle(context, Theme.of(context).primaryColor,
                        13, FontWeight.normal),
                  ),
                  Text(
                    "Page ${widget.examPageContent.pageIndex}",
                    style: myTextStyle(context, Theme.of(context).primaryColor,
                        18, FontWeight.w900),
                  ),
                ],
              )),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                gapH4,
                Card(
                  elevation: 8,
                  // color: Theme.of(context).primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 48.0, right: 48.0, top: 8.0, bottom: 8.0),
                    child: Text('SgelaAI Response',
                        style: myTextStyle(
                            context,
                            Theme.of(context).primaryColor,
                            20,
                            FontWeight.w900)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: md.SgelaMarkdownWidget(text: responseText),
                  ),
                ),
              ],
            ),
            _showRatingBar
                ? Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: AIRatingWidget(
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
