import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/data/gemini_response_rating.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/sponsoree.dart';
import 'package:edu_chatbot/data/sponsoree_activity.dart';
import 'package:edu_chatbot/services/conversion_service.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/ui/chat/ai_rating_widget.dart';
import 'package:edu_chatbot/ui/chat/gemini_text_chat_widget.dart';
import 'package:edu_chatbot/ui/chat/sgela_markdown_widget.dart';
import 'package:edu_chatbot/ui/chat/sharing_widget.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:screenshot/screenshot.dart';

import '../../util/dark_light_control.dart';
import '../../util/functions.dart';
import '../exam/exam_link_details.dart';

class GeminiImageChatWidget extends StatefulWidget {
  const GeminiImageChatWidget(
      {super.key, required this.examLink, required this.examPageContents});

  final ExamLink examLink;
  final List<ExamPageContent> examPageContents;

  @override
  GeminiImageChatWidgetState createState() => GeminiImageChatWidgetState();
}

class GeminiImageChatWidgetState extends State<GeminiImageChatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Branding? branding;
  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  Gemini gemini = GetIt.instance<Gemini>();
  Sponsoree? sponsoree;
  static const mm = '🔵🔵🔵🔵 GeminiChatWidget  🔵🔵';
  String? aiResponseText, fingerPrint;
  int? totalTokens, promptTokens, completionTokens;
  int imageCount = 0;
  bool _showMarkdown = true;
  int elapsedTimeInSeconds = 0;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
    _controlTraffic();
  }

  bool _busy = false;

  _controlTraffic() {
    if (_getImageCount() > 0) {
      _startGeminiImageTextChat();
    } else {
      _navigateToGeminiTextChatWidget();
    }
  }

  _getData() async {
    pp('$mm ... getting data ...');
    setState(() {
      _busy = true;
    });
    try {
      sponsoree = prefs.getSponsoree();
      organization = prefs.getOrganization();
      branding = prefs.getBrand();
    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  _startGeminiImageTextChat() async {
    const mx = '😎😎😎 ';
    pp('\n\n$mm ...$mx  _startGeminiImageTextChat .... 🍎 with ${widget.examPageContents.length} pages');
    setState(() {
      aiResponseText = null;
    });
    var start = DateTime.now();
    widget.examPageContents
        .sort((a, b) => a.pageIndex!.compareTo(b.pageIndex!));
    Directory directory = await getApplicationDocumentsDirectory();
    List<Uint8List> images = [];
    String totalText = '';
    totalTokens = 0;
    aiModel = 'Gemini Pro Vision';
    try {
      StringBuffer sb = _buildPromptContext();
      for (var page in widget.examPageContents) {
        if (page.pageImageUrl != null) {
          try {
            File file = File('${directory.path}/file_${page.pageIndex}.png');
            file.writeAsBytesSync(page.uBytes!);
            images.add(file.readAsBytesSync());
          } catch (e, s) {
            pp(e);
            pp(s);
          }
        } else {
          sb.write(page.text);
          sb.write('\n');
        }
      }
      //
      String text = sb.toString();
      totalText = '$totalText$text';

      pp('$mm ... $mx  ... sending prompt with image(s) for Gemini: \n $text '
          '$mx totalText length in prompt: ${totalText.length} ');
      pp('$mm ... $mx  ... prompt with image for Gemini: $mx totalTokens : $totalTokens ');

      var response = await gemini
          .textAndImage(
              text: text,
              images: images,
              generationConfig:
                  GenerationConfig(temperature: 0.0, maxOutputTokens: 5000))
          .catchError((e) => pp('$mm ERROR Gemini AI - $e'));

      if (response!.finishReason == 'stop' || response.finishReason == 'STOP') {
        pp('$mm ... $mx  ... Gemini AI has responded!');
        var sb = StringBuffer();
        response.content?.parts?.forEach((parts) {
          sb.write(parts.text);
          sb.write("\n");
        });
        aiResponseText = sb.toString();
        if (isValidLaTeXString(aiResponseText!)) {
          // aiResponseText = addNewLinesToLaTeXHeadings(aiResponseText!);
          _showMarkdown = false;
        }
      } else {
        pp('$mm ERROR: Finish reason is: ${response.finishReason}');
        if (mounted) {
          showErrorDialog(context, 'SgelaAI could not help you at this time');
        }
      }
      pp('$mm $mx ...... Gemini says: $aiResponseText');
    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    var end = DateTime.now();
    elapsedTimeInSeconds = end.difference(start).inSeconds;
    _writeSponsoreeActivity('Gemini Pro Vision');
    // setState(() {});
  }

  StringBuffer _buildPromptContext() {
    var sb = StringBuffer();
    sb.write(
        'These are questions and problems from an ${widget.examLink.subject?.title!} examination paper.\n');
    sb.write('Answer all the questions or solve all the problems.\n');
    sb.write('Think step by step.\n');
    sb.write('Explain your answers and solutions.\n');
    sb.write(
        'Separate the question responses using spacing, paragraphs or headings.\n');
    sb.write(
        'Return your response in Markdown or LaTex format where appropriate.\n');
    sb.write(
        'If mathematical or other science equations are in your response, return the response in LaText format only.\n\n');
    sb.write(
        'Return response in either Markdown or LaTex. Do not mix the 2 formats in one response');
    return sb;
  }

  _navigateToGeminiTextChatWidget() async {
    pp('\n\n$mm ... 🥦🥦🥦 _navigateToGeminiTextChatWidget: .... '
        '🍎 with ${widget.examPageContents.length} pages');
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      NavigationUtils.navigateToPage(context: context, widget: GeminiTextChatWidget(
             examLink: widget.examLink, examPageContents: widget.examPageContents));
    }
  }


  void _resetCounters() {
    promptTokens = 0;
    completionTokens = 0;
    totalTokens = 0;
  }

  String aiModel = 'Gemini Pro';
  bool ratingHasBeenDone = false;

  _openRatingDialog() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            content: AIRatingWidget(
                onRating: (rating) {
                  Navigator.of(context).pop();
                  _writeRating(rating);
                },
                visible: true),
          );
        });
  }

  _writeRating(double rating) async {
    try {
      setState(() {
        ratingHasBeenDone = false;
      });
      var mr = AIResponseRating(
          aiModel: aiModel,
          organizationId: organization?.id,
          sponsoreeId: sponsoree?.id,
          sponsoreeName: sponsoree?.sgelaUserName,
          sponsoreeEmail: sponsoree?.sgelaEmail,
          sponsoreeCellphone: sponsoree?.sgelaCellphone,
          subjectId: widget.examLink.subject?.id,
          subject: widget.examLink.subject?.title,
          id: DateTime.now().millisecondsSinceEpoch,
          rating: rating.toInt(),
          userId: sponsoree?.sgelaUserId,
          examTitle:
              '${widget.examLink.documentTitle} - ${widget.examLink.title}',
          date: DateTime.now().toUtc().toIso8601String(),
          numberOfPagesInQuery: widget.examPageContents.length,
          tokensUsed: totalTokens,
          examLinkId: widget.examLink.id);

      pp('$mm ....... add AIResponseRating to database ... ');
      myPrettyJsonPrint(mr.toJson());
      await firestoreService.addRating(mr);
      pp('$mm ... AIResponseRating added to database ... ');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
  }

  String replaceKeywordsWithBlanks(String text) {
    String modifiedText = text
        .replaceAll("Copyright reserved", "")
        .replaceAll("Please turn over", "");
    return modifiedText;
  }

  String addNewLinesToLaTeXHeadings(String input) {
    RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    var res = input.replaceAllMapped(
        regex, (match) => '\n\n**${match.group(1)}**\n\n');
    pp('$mm addNewLinesToLaTeXHeadings: $res');
    return res;
  }

  int _getImageCount() {
    int cnt = 0;
    for (var value in widget.examPageContents) {
      if (value.pageImageUrl != null) {
        pp('$mm ... contentBag: image in the page, index: 🍎🍎${value.pageIndex} 🍎🍎');
        cnt++;
      }
    }

    imageCount = cnt;
    return imageCount;
  }

  FirestoreService firestoreService = GetIt.instance<FirestoreService>();

  _writeSponsoreeActivity(String model) async {
    setState(() {
      _busy = true;
    });
    try {
      var act = SponsoreeActivity(
          organizationId: organization?.id,
          id: DateTime.now().millisecondsSinceEpoch,
          date: DateTime.now().toUtc().toIso8601String(),
          organizationName: organization?.name,
          examLinkId: widget.examLink.id!,
          totalTokens: totalTokens,
          aiModel: model,
          elapsedTimeInSeconds: elapsedTimeInSeconds,
          sponsoreeCellphone: sponsoree?.sgelaCellphone,
          sponsoreeEmail: sponsoree?.sgelaEmail,
          sponsoreeName: sponsoree?.sgelaUserName,
          subjectId: widget.examLink.subject?.id!,
          examTitle:
              '${widget.examLink.documentTitle} - ${widget.examLink.title}',
          subject: widget.examLink.subject?.title,
          userId: sponsoree?.sgelaUserId,
          sponsoreeId: sponsoree?.id!);

      pp('$mm ... add SponsoreeActivity to database ... ');
      myPrettyJsonPrint(act.toJson());
      await firestoreService.addSponsoreeActivity(act);
      pp('$mm ... SponsoreeActivity added to database ... ');
    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  ConversionService conversionService = GetIt.instance<ConversionService>();

  _navigateToSharing() async {
    pp('$mm ........................... '
        '_shareAIResponse - _navigateToSharing .....');

    NavigationUtils.navigateToPage(
        context: context,
        widget: SharingWidget(
            examPageContents: widget.examPageContents,
            aiResponseText: aiResponseText!,
            examLink: widget.examLink));
  }

  ScreenshotController screenshotController = ScreenshotController();

  Future<File?> _captureWidget() async {
    Uint8List? image =
        await screenshotController.captureFromWidget(_showMarkdown
            ? SgelaMarkdownWidget(text: aiResponseText!)
            : Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                        TeXViewDocument(aiResponseText!),
                      ],
                    ),
                  ),
                ),
              ));
    File file = File(
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.png');
    file.writeAsBytesSync(image);
    pp('$mm ... captured ... file: ${await file.length()} bytes');

    return file;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mode = prefs.getMode();
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: branding == null
                  ? const Text('OpenAI Driver')
                  : OrgLogoWidget(
                      branding: branding,
                      height: 28,
                    ),
              actions: [
                IconButton(
                    onPressed: () {
                      _controlTraffic();
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: mode == DARK
                          ? Theme.of(context).primaryColor
                          : Colors.black,
                    )),
                aiResponseText == null? gapW4: IconButton(
                    onPressed: () {
                      _navigateToSharing();
                    },
                    icon: Icon(
                      Icons.share,
                      color: mode == DARK
                          ? Theme.of(context).primaryColor
                          : Colors.black,
                    )),
              ],
            ),
            body: ScreenTypeLayout.builder(
              mobile: (_) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          ExamLinkDetails(
                            examLink: widget.examLink,
                            pageNumber:
                                widget.examPageContents.first.pageIndex! + 1,
                          ),
                          gapH16,
                          aiResponseText == null
                              ? gapW4
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'SgelaAI Response',
                                      style: myTextStyleMediumLargeWithSize(
                                          context, 18),
                                    ),
                                    aiResponseText == null
                                        ? gapW4
                                        : Row(
                                            children: [
                                              gapW32,
                                              IconButton(
                                                  onPressed: () {
                                                    _openRatingDialog();
                                                  },
                                                  icon: Icon(
                                                    Icons.star_rate,
                                                    color: mode == DARK
                                                        ? Theme.of(context)
                                                            .primaryColor
                                                        : Colors.black,
                                                  ))
                                            ],
                                          )
                                  ],
                                ),
                          gapH16,
                          aiResponseText == null
                              ? const BusyIndicator(
                                  caption: 'Talking to SgelaAI ...',
                                  showClock: true,
                                )
                              : Expanded(
                                  child: _showMarkdown
                                      ? SgelaMarkdownWidget(
                                          text: aiResponseText!)
                                      : Card(
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
                                                      aiResponseText!),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                          const SponsoredBy(),
                        ],
                      ),
                    )
                  ],
                );
              },
              tablet: (_) {
                return const Stack();
              },
              desktop: (_) {
                return const Stack();
              },
            )));
  }
}
