import 'dart:io';
import 'dart:typed_data';

import 'package:dart_openai/dart_openai.dart';
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/ui/chat/markdown_widget.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/powered_by.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../util/dark_light_control.dart';
import '../../util/functions.dart';

class AICommunicationsWidget extends StatefulWidget {
  const AICommunicationsWidget(
      {super.key, required this.examLink, required this.examPageContents});

  final ExamLink examLink;
  final List<ExamPageContent> examPageContents;

  @override
  AICommunicationsWidgetState createState() => AICommunicationsWidgetState();
}

class AICommunicationsWidgetState extends State<AICommunicationsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Branding? branding;
  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  Gemini gemini = GetIt.instance<Gemini>();

  static const mm = '🔵🔵🔵🔵 OpenAIDriver  🔵🔵';

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
      _startImageTextChat();
    } else {
      _startChat();
    }
  }

  _getData() async {
    pp('$mm ... getting data ...');
    setState(() {
      _busy = true;
    });
    try {
      organization = prefs.getOrganization();
      branding = prefs.getBrand();
      // List<OpenAIModelModel> models = await OpenAI.instance.model.list();
      // for (var model in models) {
      //   pp('$mm OpenAI model: ${model.id} 🍎🍎ownedBy: ${model.ownedBy}');
      // }
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

  _startImageTextChat() async {
    pp('\n\n$mm ...😎😎😎 _startImageTextChat .... 🍎 with ${widget.examPageContents.length} pages');
    setState(() {
      aiResponseText = null;
    });
    widget.examPageContents
        .sort((a, b) => a.pageIndex!.compareTo(b.pageIndex!));
    Directory directory = await getApplicationDocumentsDirectory();
    List<Uint8List> images = [];
    try {
      var sb = StringBuffer();

      sb.write('These are questions and problems from an ${widget.examLink.subject?.title!} examination paper.\n');
      sb.write('Answer all the questions or solve all the problems.\n');
      sb.write(
          'Separate the question responses using spacing, paragraphs or headings.\n');
      sb.write('Return your response in Markdown format where appropriate.\n');
      sb.write(
          'If mathematical or other science equations are in your response, return the response in LaText format.\n\n');
      sb.write('Return response in either Markdown or LaTex. Do not mix the 2 formats in one response');
      for (var page in widget.examPageContents) {
        if (page.pageImageUrl != null) {
          File file = File('${directory.path}/file_${page.pageIndex}.png');
          file.writeAsBytesSync(page.uBytes!);
          images.add(file.readAsBytesSync());
        } else {
          sb.write(page.text);
          sb.write('\n');
        }
      }
      //
      String text = sb.toString();
      pp('$mm ... 😎😎😎 ... sending prompt with image for Gemini: \n $text 😎😎😎');
      var response = await gemini
          .textAndImage(
              text: text,
              images: images,
              generationConfig:
                  GenerationConfig(temperature: 0.1, maxOutputTokens: 5000))
          .catchError((e) => pp('$mm ERROR Gemini AI - $e'));
      if (response!.finishReason == 'stop' || response.finishReason == 'STOP') {
        pp('$mm ... 😎😎😎 ... Gemini AI has responded!');
        var sb = StringBuffer();
        response.content?.parts?.forEach((parts) {
          sb.write(parts.text);
          sb.write("\n");
        });
        aiResponseText = sb.toString();
        pp('$mm 😎😎😎Gemini says: $aiResponseText');
        if (isValidLaTeXString(aiResponseText!)) {
          _showMarkdown = false;
        }
      } else {
        pp('$mm ERROR: Finish reason is: ${response.finishReason}');
        if (mounted) {
          showErrorDialog(context, 'SgelaAI could not help you at this time');
        }
      }
    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {});
  }

  _startChat() async {
    pp('\n\n$mm ... 🥦🥦🥦 starting OpenAI chat .... 🍎 with ${widget.examPageContents.length} pages');

    await Future.delayed(const Duration(milliseconds: 20));
    // the system message that will be sent to the request.
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
          "Return any response you make as Markdown. When working with mathematics or physics equations, return as LaTex",
        ),
      ],
      role: OpenAIChatMessageRole.system,
    );

    // the user message that will be sent to the request.
    StringBuffer stringBuffer = StringBuffer();
    for (var page in widget.examPageContents) {
      stringBuffer.write('${replaceKeywordsWithBlanks(page.text!)}\n');
    }
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          stringBuffer.toString(),
        ),

        //! image url contents are allowed only for models with image support such gpt-4.
        // OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
        //   "https://placehold.co/600x400",
        // ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    // all messages to be sent.
    final requestMessages = [
      systemMessage,
      userMessage,
    ];
    pp('$mm ... 🥦🥦🥦sending prompt for OpenAI: ${stringBuffer.toString()}');
    setState(() {
      _busy = true;
      aiResponseText = null;
    });
    try {
      pp('$mm ... 🥦🥦🥦creating OpenAIChatCompletionModel ....'); // the actual request.
      OpenAIChatCompletionModel chatCompletion =
          await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo-1106",
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
      //
      if (chatCompletion.haveChoices) {
        aiResponseText =
            chatCompletion.choices.first.message.content?.first.text;
        pp('$mm ... 🥦🥦🥦completion.choices.first.finishReason: 🍎🍎 ${chatCompletion.choices.first.finishReason}');
        if (chatCompletion.choices.first.finishReason == 'stop') {
          pp('$mm ...🥦🥦🥦 💛everything is OK, Boss!!, 💛 SgelaAI has responded with answers ...');
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
    setState(() {
      _busy = false;
    });
  }

  void _printResults(OpenAIChatCompletionModel chatCompletion) {
    pp('$mm OpenAIChatCompletion completion.choices.first.message: 🍎🍎 ${chatCompletion.choices.first.message}'); // ...
    pp('$mm OpenAIChatCompletion promptTokens : 🍎🍎${chatCompletion.usage.promptTokens}'); // ...
    pp('$mm OpenAIChatCompletion completionTokens: 🍎🍎${chatCompletion.usage.completionTokens}');
    pp('$mm OpenAIChatCompletion totalTokens: 🍎🍎${chatCompletion.usage.totalTokens}');
    pp('$mm OpenAIChatCompletion chatCompletion.id: 🍎🍎${chatCompletion.id}');
    pp('$mm OpenAIChatCompletion systemFingerprint: 🍎🍎${chatCompletion.systemFingerprint}');
  }

  String? aiResponseText, fingerPrint;
  int? totalTokens, promptTokens, completionTokens;
  int imageCount = 0;
  bool _showMarkdown = true;

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
        pp('$mm ... contentBag: image in the page, index: 🍎🍎${value.pageIndex} 🍎🍎');
        cnt++;
      }
    }

    imageCount = cnt;
    return imageCount;
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
                      _startChat();
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: mode == DARK
                          ? Theme.of(context).primaryColor
                          : Colors.black,
                    )),
                IconButton(
                    onPressed: () {
                      showToast(
                          padding: 20,
                          backgroundColor: Colors.pink,
                          textStyle: const TextStyle(color: Colors.white),
                          message: 'Sharing Under Construction',
                          context: context);
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
                                          context, 20),
                                    ),
                                    aiResponseText == null
                                        ? gapW4
                                        : Row(
                                            children: [
                                              gapW32,
                                              IconButton(
                                                  onPressed: () {
                                                    showToast(
                                                        message:
                                                            'Will rate soon',
                                                        backgroundColor:
                                                            Colors.pink,
                                                        context: context);
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
                                      ? MarkdownWidget(text: aiResponseText!)
                                      : TeXView(
                                          style: const TeXViewStyle(
                                            contentColor: Colors.white,
                                            backgroundColor: Colors.transparent,
                                            padding: TeXViewPadding.all(8),
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

class ExamLinkDetails extends StatelessWidget {
  const ExamLinkDetails(
      {super.key, required this.examLink, required this.pageNumber});

  final ExamLink examLink;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: SizedBox(
        height: pageNumber == 0 ? 64 : 80,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 20.0, right: 20.0, top: 8.0, bottom: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${examLink.documentTitle}',
                style: myTextStyleSmall(context),
              ),
              Text(
                '${examLink.title}',
                style: myTextStyleSmall(context),
              ),
              gapH8,
              pageNumber == 0
                  ? gapW4
                  : Text(
                      'Page $pageNumber',
                      style: myTextStyleSmallBoldPrimaryColor(context),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
