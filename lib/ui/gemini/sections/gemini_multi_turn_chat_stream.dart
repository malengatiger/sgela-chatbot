import 'dart:io';

import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/local_util/functions.dart';
import 'package:edu_chatbot/ui/chat/latex_math_viewer.dart';
import 'package:edu_chatbot/ui/gemini/widgets/chat_input_box.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:sgela_services/data/tokens_used.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/local_data_service.dart';
import 'package:sgela_services/sgela_util/db_methods.dart';
import 'package:sgela_services/sgela_util/dio_util.dart';
import 'package:sgela_services/sgela_util/environment.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

class GeminiMultiTurnStreamChat extends StatefulWidget {
  const GeminiMultiTurnStreamChat(
      {super.key, this.examLink, this.examPageContents, this.subject});

  final ExamLink? examLink;
  final List<ExamPageContent>? examPageContents;
  final Subject? subject;
  @override
  State<GeminiMultiTurnStreamChat> createState() =>
      GeminiMultiTurnStreamChatState();
}

class GeminiMultiTurnStreamChatState extends State<GeminiMultiTurnStreamChat> {
  static const mm = '🍐🍐🍐🍐 GeminiMultiTurnStreamChat 🍐';

  bool _busy = false;

  bool get loading => _busy;
  int turnNumber = 0;

  set loading(bool set) => setState(() => _busy = set);

  Prefs prefs = GetIt.instance<Prefs>();
  LocalDataService localDataService = GetIt.instance<LocalDataService>();
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  Branding? branding;
  final _chatInputController = TextEditingController();
  ExamPageContent? examPageContent;
  String? _examPageText;
  String textPrompt = 'Hello SgelaAI';
  int chatStartCount = 0;

  DioUtil dioUtil = GetIt.instance<DioUtil>();

  int totalTokens = 0;
  int insertIndex = 10;

  List<gai.Content> contents = [];
  List<gai.TextPart> systemPartsContext = [];
  gai.ChatSession? chatSession;
  String? aiResponseText;
  late gai.GenerativeModel generativeModel;
  Organization? organization;
  Sponsoree? sponsoree;

  @override
  void initState() {
    super.initState();
    generativeModel = gai.GenerativeModel(
        model: 'gemini-pro', apiKey: ChatbotEnvironment.getGeminiAPIKey());
    _getOrganizationAndSponsoree();
    _getPageContents();
  }

  _getOrganizationAndSponsoree() {
    organization = prefs.getOrganization();
    sponsoree = prefs.getSponsoree();
  }

  _getPageContents() async {
    var sb = StringBuffer();
    if (widget.examPageContents != null) {
      widget.examPageContents?.forEach((page) {
        if (page.text != null) {
          sb.write('${page.text!}\n');
        }
      });
    }
    _examPageText = sb.toString();
    if (widget.subject != null) {
      _examPageText = 'Help me with ${widget.subject?.title}';
    }
    _handleInputText(true);
    setState(() {});
  }

  void _handleInputText(bool isFirstTime) {
    if (isFirstTime) {
      if (_examPageText != null && _examPageText!.isNotEmpty) {
        textPrompt = _examPageText!;
      }
    } else {
      if (_chatInputController.text.isNotEmpty) {
        textPrompt = _chatInputController.text;
      } else {
        textPrompt = 'Hello';
      }
    }
    if (textPrompt.isNotEmpty) {
      textPrompt = _replaceKeywordsWithBlanks(textPrompt);

      if (contents.length > insertIndex) {
        int rem = contents.length % 10;
        if (rem == 0) {
          contents.add(gai.Content('model', systemPartsContext));
          pp('$mm ... System Context inserted  -- contents: ${contents
              .length}');
        }
      }
      _chatInputController.clear();
      _sendChatMessage();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you 🍎🍎🍎',
          context: context);
    }
  }

  Future<void> _addTokensUsed() async {
    try {
      pp('$mm count tokens used in session ... ');
      var ctr = await generativeModel.countTokens(contents);
      totalTokens = ctr.totalTokens;
      if (sponsoree != null) {
        DBMethods.addTokensUsed(totalTokens, sponsoree!, 'gemini-pro');
      }
    } catch (e, s) {
      pp("ERROR counting tokens: $e $s");
    }
    setState(() {});
  }

  Future<void> _sendChatMessage() async {
    pp(
        '$mm _startAndListenToChatStream ...... 🍎🍎🍎🍎\nprompt: 🍎$textPrompt🍎🍎🍎🍎 ');
    try {
      setState(() {
        _busy = true;
      });

      if (chatSession == null) {
        List<gai.TextPart> modelTextParts = _buildModelPromptContext();
        List<gai.TextPart> userTextParts = _buildUserPromptContext();
        contents.add(gai.Content('model', modelTextParts));
        contents.add(gai.Content('user', userTextParts));
        chatSession = generativeModel.startChat(
            history: contents,
            generationConfig: gai.GenerationConfig(temperature: 0.2));
      }

      gai.GenerateContentResponse response = await chatSession!
          .sendMessage(gai.Content('user', [gai.TextPart(textPrompt)]));

      if (response.candidates.first.finishReason != null) {
        pp('$mm ... finish reason: ${response.candidates.first.finishReason
            ?.name} '
            '🔆 ${response.candidates.first.finishReason?.toString()}');
        var reason = response.candidates.first.finishReason!.name;
        if (reason == 'stop' || reason == 'STOP') {
          aiResponseText = response.text;
          contents.add(gai.Content('model', [gai.TextPart(response.text!)]));
        } else {
          aiResponseText =
          'Sorry! SgelaAI was unable to help with your request. Please try again 🔆';
        }
      }
    } catch (e, s) {
      pp('$mm ERROR: $e - $s');
    }
    setState(() {
      _busy = false;
    });
  }

  List<gai.TextPart> _buildUserPromptContext() {
    List<gai.TextPart> textParts = [];
    textParts.add(gai.TextPart(
        'I need your help with ${widget.examLink?.subject
            ?.title} examination paper'));
    textParts.add(gai.TextPart(
        'Help me prepare for this examination. I am in high school or college.'));
    textParts.add(gai.TextPart(
        'Answer all the questions or solve all the problems that you find in the image.'));
    textParts.add(gai.TextPart('Think step by step.'));
    textParts.add(gai.TextPart('Be concise.'));
    textParts.add(gai.TextPart(
        'Explain your answers and solutions like I am between 8 and 22 years old.'));
    textParts.add(gai.TextPart('Show proof of your solution.'));
    textParts.add(gai.TextPart(
        'Separate the question responses using spacing, paragraphs or headings.'));
    textParts.add(gai.TextPart('Return response in Markdown format.'));

    return textParts;
  }

  List<gai.TextPart> _buildModelPromptContext() {
    List<gai.TextPart> textParts = [];
    textParts.add(gai.TextPart(
        'I am a super ${widget.examLink?.subject
            ?.title} tutor and personal AI assistant'));
    textParts.add(gai.TextPart('I do my best to give accurate responses'));
    return textParts;
  }

  Widget chatItem(BuildContext context, int index) {
    String role = 'You';
    if (contents.isNotEmpty && contents.last.role == 'model') {
      role = 'SgelaAI';
    }
    bool isLatex =
    isValidLaTeXString(aiResponseText == null ? '' : aiResponseText!);
    if (isLatex) {
      return Card(
        elevation: 0,
        color: role == 'SgelaAI' ? Colors.blue.shade800 : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role),
              Card(
                elevation: 8,
                child: aiResponseText == null
                    ? gapH8
                    : LaTexCard(
                  text: aiResponseText!,
                  showHeader: false,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      color: contents.isEmpty
          ? Colors.transparent
          : contents.last.role == 'model'
          ? Colors.blue.shade800
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            Card(
              elevation: 8,
              color: contents.isEmpty
                  ? Colors.transparent
                  : contents.last.role == 'model'
                  ? Colors.blue.shade800
                  : Colors.transparent,
              child: aiResponseText == null
                  ? gapH8
                  : Markdown(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  data: aiResponseText!),
            ),
          ],
        ),
      ),
    );
  }
  String _replaceKeywordsWithBlanks(String text) {
    String modifiedText = text
        .replaceAll("Copyright reserved", "")
        .replaceAll("Please turn over", "");
    return modifiedText;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addTokensUsed();
              },
              icon: Platform.isAndroid
                  ? const Icon(Icons.arrow_back)
                  : const Icon(Icons.arrow_back_ios),
            ),
            title: Row(
              children: [
                loading
                    ? gapW4
                    : Text(
                  'Chat with ',
                  style: myTextStyleSmall(context),
                ),
                gapW8,
                loading
                    ? gapW4
                    : Text(
                  'SgelaAI',
                  style: myTextStyle(context, Theme
                      .of(context)
                      .primaryColor,
                      24, FontWeight.w900),
                ),
                gapW16,
                Text(
                  '(Gemini AI)',
                  style: myTextStyleTiny(context),
                )
              ],
            ),
            actions: [
              if (loading)
                const BusyIndicator(
                  showTimerOnly: true,
                ),
              IconButton(
                  onPressed: () {
                    pp('$mm ... do the Share thing ...');
                  },
                  icon: Icon(Icons.share, color: Theme
                      .of(context)
                      .primaryColor)),
            ],
          ),
          body: SizedBox(
            height: double.infinity,
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                        child: contents.isNotEmpty
                            ? Align(
                          alignment: Alignment.bottomCenter,
                          child: bd.Badge(
                            badgeContent: Text('${contents.length}'),
                            position:
                            bd.BadgePosition.topEnd(top: -16, end: -8),
                            badgeStyle: const bd.BadgeStyle(
                              padding: EdgeInsets.all(12.0),
                            ),
                            onTap: () {
                              pp('$mm badge tapped, scroll up or down');
                              _scrollDown();
                            },
                            child: SingleChildScrollView(
                              reverse: true,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemBuilder: chatItem,
                                  shrinkWrap: true,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  itemCount: contents.length,
                                  reverse: false,
                                ),
                              ),
                            ),
                          ),
                        )
                            : const Center(
                            child: Text('Say something to SgelaAI'))),
                    Card(
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ChatInputBox(
                          controller: _chatInputController,
                          onSend: () {
                            _handleInputText(false);
                          },
                        ),
                      ),
                    ),
                    const SponsoredBy(
                      height: 32,
                    ),
                  ],
                ),
                loading
                    ? const Positioned(
                    bottom: 24,
                    left: 24,
                    child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Center(
                            child: BusyIndicator(
                              showTimerOnly: true,
                            ))))
                    : gapW4,
              ],
            ),
          ),
        ));
  }

  final ScrollController _scrollController = ScrollController();

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
}
