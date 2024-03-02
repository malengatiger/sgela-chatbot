import 'dart:io';
import 'dart:typed_data';

import 'package:edu_chatbot/ui/chat/ai_rating_widget.dart';
import 'package:edu_chatbot/ui/chat/gemini_text_chat_widget.dart';
import 'package:edu_chatbot/ui/chat/latex_math_viewer.dart';
import 'package:edu_chatbot/ui/chat/sgela_markdown_widget.dart';
import 'package:edu_chatbot/ui/chat/sharing_widget.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;
import 'package:path_provider/path_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/gemini_response_rating.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/data/sponsoree_activity.dart';
import 'package:sgela_services/services/conversion_service.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/dark_light_control.dart';
import 'package:sgela_services/sgela_util/db_methods.dart';
import 'package:sgela_services/sgela_util/environment.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

import '../../local_util/functions.dart';
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
  final ScrollController _scrollController = ScrollController();

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

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
          (_) =>
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(
              milliseconds: 750,
            ),
            curve: Curves.easeOutCirc,
          ),
    );
  }

  _startGeminiImageTextChat() async {
    const mx = '😎😎😎 ';
    pp('\n\n$mm ...$mx  _startGeminiImageTextChat .... 🍎 with ${widget
        .examPageContents.length} pages');
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
    List<gai.TextPart> userTextParts = [];
    List<gai.TextPart> modelTextParts = [];

    try {
      if (widget.examLink.subject!.title != null) {
        if (widget.examLink.subject!.title!.contains('MATH')) {
          userTextParts = _buildUserMathPromptContext();
          modelTextParts = _buildModelMathPromptContext();
        }
      } else {
        userTextParts = _buildUserPromptContext();
        modelTextParts = _buildModelPromptContext();
      }
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
          userTextParts.add(gai.TextPart('${page.text}'));
        }
      }
      //

      pp('$mm ... $mx  ... sending prompt with image(s) for Gemini: \n ');

      final model = gai.GenerativeModel(
          model: 'gemini-pro', apiKey: ChatbotEnvironment.getGeminiAPIKey());
      List<gai.Content> contents = [];
      List<gai.DataPart> dataParts = [];
      for (var img in images) {
        dataParts.add(gai.DataPart('image/png', img));
      }

      contents.add(gai.Content('model', modelTextParts));
      contents.add(gai.Content('user', dataParts));
      contents.add(gai.Content('user', userTextParts));

      gai.CountTokensResponse countTokensResponse =
      await model.countTokens(contents);
      pp('$mm CountTokensResponse:  🌍🌍🌍🌍tokens: ${countTokensResponse
          .totalTokens}  🌍🌍🌍🌍');

      final gai.GenerateContentResponse response =
      await model.generateContent(contents);
      if (response.candidates.first.finishMessage == 'stop' ||
          response.candidates.first.finishMessage == 'STOP') {
        aiResponseText = response.text;
        if (isValidLaTeXString(aiResponseText!)) {
          // aiResponseText = addNewLinesToLaTeXHeadings(aiResponseText!);
          _showMarkdown = false;
        }
      } else {
        pp('$mm BAD FINISH REASON: ${response.candidates.first.finishMessage}'
            ' ${response.candidates.first.finishReason.toString()}');
        if (mounted) {
          showErrorDialog(context,
              'SgelaAI could not help you at this time. Try again later.');
        }
      }
      pp('$mm $mx ...... Gemini says: $aiResponseText');
    } catch (e, s) {
      pp('$mm ERROR: $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    var end = DateTime.now();
    elapsedTimeInSeconds = end
        .difference(start)
        .inSeconds;
    _writeSponsoreeActivity('Gemini Pro Vision');
    // setState(() {});
  }

  List<gai.TextPart> _buildUserMathPromptContext() {
    List<gai.TextPart> textParts = [];
    textParts.add(gai.TextPart(
        'The image is of a page from a Mathematics examination paper'));
    textParts.add(gai.TextPart(
        'Help me prepare for this examination. I am in high school or freshman college.'));
    textParts.add(gai.TextPart(
        'Answer all the questions or solve all the problems that you find in the image.'));
    textParts.add(gai.TextPart('Think step by step.'));
    textParts.add(gai.TextPart('Be concise.'));
    textParts.add(gai.TextPart(
        'Explain your answers and solutions like I am between 8 and 20 years old.'));
    textParts.add(gai.TextPart('Show proof of your solution.'));
    textParts.add(gai.TextPart(
        'Separate the question responses using spacing, paragraphs or headings.'));
    textParts.add(gai.TextPart('Return response in LaTex format.'));

    return textParts;
  }

  List<gai.TextPart> _buildModelMathPromptContext() {
    List<gai.TextPart> textParts = [];
    textParts.add(gai.TextPart(
        'I am a super Mathematics tutor and personal AI assistant'));
    textParts.add(gai.TextPart('I do my best to give accurate responses'));
    return textParts;
  }

  List<gai.TextPart> _buildUserPromptContext() {
    List<gai.TextPart> textParts = [];
    textParts.add(gai.TextPart(
        'The image is of a page from a ${widget.examLink.subject
            ?.title} examination paper'));
    textParts.add(gai.TextPart(
        'Help me prepare for this examination. I am in high school or freshman college.'));
    textParts.add(gai.TextPart(
        'Answer all the questions or solve all the problems that you find in the image.'));
    textParts.add(gai.TextPart('Think step by step.'));
    textParts.add(gai.TextPart('Be concise.'));
    textParts.add(gai.TextPart(
        'Explain your answers and solutions like I am between 8 and 20 years old.'));
    textParts.add(gai.TextPart('Show proof of your solution.'));
    textParts.add(gai.TextPart(
        'Separate the question responses using spacing, paragraphs or headings.'));
    textParts.add(gai.TextPart('Return response in Markdown format.'));

    return textParts;
  }

  List<gai.TextPart> _buildModelPromptContext() {
    List<gai.TextPart> textParts = [];
    textParts.add(gai.TextPart('I am a super ${widget.examLink
      ..subject?.title} tutor and personal AI assistant'));
    textParts.add(gai.TextPart('I do my best to give accurate responses'));
    return textParts;
  }

  _navigateToGeminiTextChatWidget() async {
    pp('\n\n$mm ... 🥦🥦🥦 _navigateToGeminiTextChatWidget: .... '
        '🍎 with ${widget.examPageContents.length} pages');
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      NavigationUtils.navigateToPage(
          context: context,
          widget: GeminiTextChatWidget(
              examLink: widget.examLink,
              examPageContents: widget.examPageContents));
    }
  }


  String aiModel = 'Gemini Pro';
  bool ratingHasBeenDone = false;
  int tokensUsed = 0;

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
      DBMethods.addRating(rating, sponsoree!, aiModel, widget.examLink,
          widget.examPageContents.length);
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
        pp('$mm ... contentBag: image in the page, index: 🍎🍎${value
            .pageIndex} 🍎🍎');
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
          id: DateTime
              .now()
              .millisecondsSinceEpoch,
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
                  ? const Text('Gemini Image Text Driver')
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
                          ? Theme
                          .of(context)
                          .primaryColor
                          : Colors.black,
                    )),
                aiResponseText == null
                    ? gapW4
                    : IconButton(
                    onPressed: () {
                      _navigateToSharing();
                    },
                    icon: Icon(
                      Icons.share,
                      color: mode == DARK
                          ? Theme
                          .of(context)
                          .primaryColor
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
                                    context, 16),
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
                                            ? Theme
                                            .of(context)
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
                                  : SgelaLaTexViewer(
                                  text: aiResponseText!,
                                  examPageContents:
                                  widget.examPageContents,
                                  tokensUsed: tokensUsed,
                                  examLink: widget.examLink)),
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
