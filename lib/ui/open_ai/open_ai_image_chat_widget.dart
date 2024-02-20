import 'package:dart_openai/dart_openai.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/gemini_response_rating.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/data/sponsoree_activity.dart';
import 'package:sgela_services/data/tokens_used.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:edu_chatbot/ui/chat/ai_model_selector.dart';
import 'package:edu_chatbot/ui/chat/ai_rating_widget.dart';
import 'package:edu_chatbot/ui/chat/sgela_markdown_widget.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:sgela_services/sgela_util/dark_light_control.dart';
import 'package:sgela_services/sgela_util/environment.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../local_util/functions.dart';
import '../exam/exam_link_details.dart';

class OpenAIImageChatWidget extends StatefulWidget {
  const OpenAIImageChatWidget({
    super.key,
    required this.examLink,
    required this.examPageContents,
  });

  final ExamLink examLink;
  final List<ExamPageContent> examPageContents;

  @override
  OpenAIImageChatWidgetState createState() => OpenAIImageChatWidgetState();
}

class OpenAIImageChatWidgetState extends State<OpenAIImageChatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Branding? branding;
  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  Sponsoree? sponsoree;
  static const mm = '🔵🔵🔵🔵 OpenAIImageChatWidget  🔵🔵';
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
      _startOpenAIChatWithImages();
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

  _startOpenAIChatWithImages() async {
    pp('\n\n$mm ... 🥦🥦🥦 _startOpenAIChatWithImages: .... 🍎 ');
    var start = DateTime.now();
    aiModel = 'OpenAI';
    _resetCounters();

    await Future.delayed(const Duration(milliseconds: 20));
    setState(() {
      _busy = true;
      aiResponseText = null;
    });
    // the system message that will be sent to the request.
    OpenAIChatCompletionChoiceMessageModel systemMessage =
    _buildOpenAISystemMessage();

    // the user message that will be sent to the request.
    OpenAIChatCompletionChoiceMessageModel userMessage =
    _buildOpenAIUserMessageWithImages();

    final requestMessages = [
      systemMessage,
      userMessage,
    ];

    try {
      pp(
          '$mm ... 🥦🥦🥦creating OpenAIChatCompletionModel ....'); // the actual request.
      OpenAIChatCompletionModel chatCompletion =
      await OpenAI.instance.chat.create(
        model: ChatbotEnvironment.getOpenAIVisionModel(),
        // responseFormat: {"type": "markdown"},
        seed: 6,
        messages: requestMessages,
        temperature: 0.0,
        maxTokens: 1000,
        // toolChoice: "auto",
      );

      _printResults(chatCompletion);

      promptTokens = chatCompletion.usage.promptTokens;
      completionTokens = chatCompletion.usage.completionTokens;
      totalTokens = chatCompletion.usage.totalTokens;
      fingerPrint = chatCompletion.systemFingerprint;
      _addTokensUsed(chatCompletion);
      //
      if (chatCompletion.haveChoices) {
        aiResponseText =
            chatCompletion.choices.first.message.content?.first.text;
        pp(
            '$mm ... 🥦🥦🥦completion.choices.first.finishReason: 🍎🍎 ${chatCompletion
                .choices.first.finishReason}');
        if (chatCompletion.choices.first.finishReason == 'stop') {
          pp(
              '$mm ...🥦🥦🥦 💛everything is OK, Boss!!, 💛 OpenAI has responded with answers ...');
          _showMarkdown = true;
        } else {
          if (mounted) {
            showErrorDialog(context,
                'SgelaAI could not help you at this time. Please try again');
          }
        }
      }
    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    var end = DateTime.now();
    elapsedTimeInSeconds = end
        .difference(start)
        .inSeconds;
    _writeSponsoreeActivity('gpt-4-vision-preview');

    setState(() {
      _busy = false;
    });
  }

  OpenAIChatCompletionChoiceMessageModel _buildOpenAIUserMessageWithImages() {
    List<OpenAIChatCompletionChoiceMessageContentItemModel> messages = [];

    for (var page in widget.examPageContents!) {
      if (page.pageImageUrl != null) {
        messages.add(OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
          page.pageImageUrl!,
        ));
      }
    }
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: messages,
      role: OpenAIChatMessageRole.user,
    );
    return userMessage;
  }

  void _resetCounters() {
    promptTokens = 0;
    completionTokens = 0;
    totalTokens = 0;
  }

  OpenAIChatCompletionChoiceMessageModel _buildOpenAISystemMessage() {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You are a super tutor and educational assistant.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You answer all the questions or solve all the problems you find in the text.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You think step by step for each question or problem",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You use paragraphs, spacing or headings to separate your responses.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You suggest the ways that the reader can improve their mastery of the subject.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "Return any response you make as Markdown. When working with mathematics "
              "or physics equations, return as LaTex",
        ),
      ],
      role: OpenAIChatMessageRole.system,
    );
    return systemMessage;
  }

  OpenAIChatCompletionChoiceMessageModel _buildOpenAISystemMessageWithImages() {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You are a super tutor and educational assistant.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You answer all the questions or solve all the problems you find in the images.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You think step by step for each question or problem",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You use paragraphs, spacing or headings to separate your responses.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You suggest the ways that the reader can improve their mastery of the subject.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "Return any response you make as Markdown. When working with mathematics "
              "or physics equations, return as LaTex",
        ),
      ],
      role: OpenAIChatMessageRole.system,
    );
    return systemMessage;
  }

  void _printResults(OpenAIChatCompletionModel chatCompletion) {
    pp(
        '$mm OpenAIChatCompletion completion.choices.first.message: 🍎🍎 ${chatCompletion
            .choices.first.message}'); // ...
    pp('$mm OpenAIChatCompletion promptTokens : 🍎🍎${chatCompletion.usage
        .promptTokens}'); // ...
    pp('$mm OpenAIChatCompletion completionTokens: 🍎🍎${chatCompletion.usage
        .completionTokens}');
    pp('$mm OpenAIChatCompletion totalTokens: 🍎🍎${chatCompletion.usage
        .totalTokens}');
    pp('$mm OpenAIChatCompletion chatCompletion.id: 🍎🍎${chatCompletion.id}');
    pp('$mm OpenAIChatCompletion systemFingerprint: 🍎🍎${chatCompletion
        .systemFingerprint}');
  }

  _addTokensUsed(OpenAIChatCompletionModel chatCompletion) {
    promptTokens = chatCompletion.usage.promptTokens;
    completionTokens = chatCompletion.usage.completionTokens;
    totalTokens = chatCompletion.usage.totalTokens;

    var tokensUsed = TokensUsed(
        organization!.id!,
        sponsoree!.id!,
        DateTime.now().toUtc().toIso8601String(),
        sponsoree!.sgelaUserName!,
        organization!.name,
        promptTokens,
        completionTokens,
        modelOpenAI, totalTokens);

    firestoreService.addTokensUsed(tokensUsed);
  }

  String aiModel = 'OpenAI';
  bool ratingHasBeenDone = false;

  _openRatingToast({Color? backgroundColor,
    Duration? duration,
    double? padding,
    ToastGravity? toastGravity}) {
    FToast fToast = FToast();
    const mm = 'FunctionsAndShit: 💀 💀 💀 💀 💀 : ';
    try {
      fToast.init(context);
    } catch (e) {
      pp('$mm FToast may already be initialized');
    }
    Widget toastContainer = Container(
        width: 500,
        padding: EdgeInsets.symmetric(
            horizontal: padding ?? 8.0, vertical: padding ?? 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          // color: backgroundColor ?? Colors.black,
        ),
        child: AIRatingWidget(
            onRating: (rating) {
              Navigator.of(context).pop();
              _writeRating(rating);
            },
            visible: true));

    try {
      fToast.showToast(
        child: toastContainer,
        gravity: toastGravity ?? ToastGravity.CENTER,
        toastDuration: duration ?? const Duration(seconds: 5),
      );
    } catch (e, s) {
      pp('$mm 👿👿👿👿👿 we have a small TOAST problem, Boss! - 👿 $e');
      pp(s);
    }
  }

  int? subjectId, examLinkId;
  String? subject, examTitle;

  _writeRating(double rating) async {
    try {
      setState(() {
        ratingHasBeenDone = false;
      });

      _setVariables();
      var mr = AIResponseRating(
          aiModel: aiModel,
          organizationId: organization?.id,
          sponsoreeId: sponsoree?.id,
          sponsoreeName: sponsoree?.sgelaUserName,
          sponsoreeEmail: sponsoree?.sgelaEmail,
          sponsoreeCellphone: sponsoree?.sgelaCellphone,
          subjectId: subjectId,
          subject: subject,
          id: DateTime
              .now()
              .millisecondsSinceEpoch,
          rating: rating.toInt(),
          userId: sponsoree?.sgelaUserId,
          examTitle: examTitle,
          date: DateTime.now().toUtc().toIso8601String(),
          numberOfPagesInQuery: widget.examPageContents.length,
          tokensUsed: totalTokens,
          examLinkId: examLinkId);

      pp('$mm ....... add AIResponseRating to database ... ');
      myPrettyJsonPrint(mr.toJson());
      await firestoreService.addRating(mr);
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

  void _setVariables() {
    examLinkId = widget.examLink.id!;
    subjectId = widget.examLink.subject!.id!;
    subject = widget.examLink.subject!.title!;
    examTitle =
    '${widget.examLink.documentTitle!} - ${widget.examLink.subject!
        .title!} - ${widget.examLink.title}';
  }

  String replaceKeywordsWithBlanks(String text) {
    String modifiedText = text
        .replaceAll("Copyright reserved", "")
        .replaceAll("Please turn over", "");
    return modifiedText;
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
      _setVariables();
      var act = SponsoreeActivity(
          organizationId: organization?.id,
          id: DateTime
              .now()
              .millisecondsSinceEpoch,
          date: DateTime.now().toUtc().toIso8601String(),
          organizationName: organization?.name,
          examLinkId: examLinkId,
          totalTokens: totalTokens,
          aiModel: model,
          elapsedTimeInSeconds: elapsedTimeInSeconds,
          sponsoreeCellphone: sponsoree?.sgelaCellphone,
          sponsoreeEmail: sponsoree?.sgelaEmail,
          sponsoreeName: sponsoree?.sgelaUserName,
          subjectId: subjectId,
          examTitle: examTitle,
          subject: subject,
          userId: sponsoree?.sgelaUserId,
          sponsoreeId: sponsoree?.id!);

      pp('$mm ... add SponsoreeActivity to database ... ');
      myPrettyJsonPrint(act.toJson());
      await firestoreService.addSponsoreeActivity(act);
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _showExamDetails = false;

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
                      setState(() {
                        _showExamDetails = !_showExamDetails;
                      });
                    },
                    icon: Icon(
                      Icons.question_mark,
                      color: mode == DARK
                          ? Theme
                          .of(context)
                          .primaryColor
                          : Colors.black,
                    )),
                // IconButton(
                //     onPressed: () {
                //       _controlTraffic();
                //     },
                //     icon: Icon(
                //       Icons.refresh,
                //       color: mode == DARK
                //           ? Theme.of(context).primaryColor
                //           : Colors.black,
                //     )),
                IconButton(
                    onPressed: () {
                      _openRatingToast();
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
                          _showExamDetails ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _showExamDetails = false;
                              });
                            },
                            child: ExamLinkDetails(
                              examLink: widget.examLink,
                              pageNumber:
                              widget.examPageContents.first.pageIndex! + 1,
                            ),
                          ) : gapW4,
                          gapH4,
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
                                        _openRatingToast();
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
                          gapH4,
                          aiResponseText == null
                              ? const BusyIndicator(
                            caption: 'Talking to SgelaAI ...',
                            showClock: true,
                          )
                              : Expanded(
                            child: _showMarkdown
                                ? SgelaMarkdownWidget(
                              text: aiResponseText!,
                              backgroundColor: Colors.teal[700]!,
                            )
                                : TeXView(
                              style: TeXViewStyle(
                                contentColor: Colors.white,
                                backgroundColor: Colors.teal[700]!,
                                padding:
                                const TeXViewPadding.all(8),
                              ),
                              renderingEngine:
                              const TeXViewRenderingEngine
                                  .katex(),
                              child: TeXViewColumn(
                                children: [
                                  TeXViewDocument(aiResponseText!),
                                ],
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
