import 'dart:io';

import 'package:badges/badges.dart' as bd;
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:edu_chatbot/gemini/widgets/chat_input_box.dart';
import 'package:sgela_services/services/local_data_service.dart';
import 'package:edu_chatbot/ui/chat/latex_math_viewer.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/dio_util.dart';
import 'package:sgela_services/sgela_util/environment.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

import '../../local_util/functions.dart';


class GeminiMultiTurnStreamChat extends StatefulWidget {
  const GeminiMultiTurnStreamChat(
      {super.key, this.examLink, this.subject, this.examPageContents});

  final ExamLink? examLink;
  final Subject? subject;
  final List<ExamPageContent>? examPageContents;

  @override
  State<GeminiMultiTurnStreamChat> createState() =>
      GeminiMultiTurnStreamChatState();
}

class GeminiMultiTurnStreamChatState extends State<GeminiMultiTurnStreamChat> {
  static const mm = '🍐🍐🍐🍐 GeminiMultiTurnStreamChat 🍐';

  bool _busy = false;
  Gemini gemini = GetIt.instance<Gemini>();

  bool get loading => _busy;
  int turnNumber = 0;

  set loading(bool set) => setState(() => _busy = set);
  final List<Content> chats = [];

  Prefs prefs = GetIt.instance<Prefs>();
  LocalDataService localDataService = GetIt.instance<LocalDataService>();
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  Branding? branding;
  var _chatInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getPageContents();
  }

  ExamPageContent? examPageContent;
  String? _examPageText;

  _getPageContents() async {
    var sb = StringBuffer();
    if (widget.subject != null) {
      _chatInputController = TextEditingController(
          text: 'I need help with this subject: ${widget.subject?.title}');
    }
    if (widget.examLink != null) {
      _chatInputController = TextEditingController(
          text:
              'I need help with this subject: ${widget.examLink!.subject?.title}');
    }
    if (widget.examPageContents != null) {
      widget.examPageContents?.forEach((page) {
        if (page.text != null) {
          sb.write('${page.text!}\n\n');
        }
      });
    }
    _examPageText = sb.toString();
    if (_examPageText != null && _examPageText!.isNotEmpty) {
      _examPageText =
          'Find the questions or problems in the text below and respond with the solutions in markdown format.\n'
          'Show solution steps where necessary.\n The text: $_examPageText';
      pp('$mm ... length of examText: ${_examPageText!.length}  bytes');
    }
    _handleInputText(true);
    setState(() {});
  }

  int insertIndex = 10;

  void _handleInputText(bool isFirstTime) {
    if (isFirstTime) {
      if (_examPageText != null && _examPageText!.isNotEmpty) {
        textPrompt = _examPageText!;
      }
    } else {
      if (_chatInputController.text.isNotEmpty) {
        textPrompt = _chatInputController.text;
      } else {
        textPrompt = '';
      }
    }
    if (textPrompt.isNotEmpty) {
      textPrompt = _replaceKeywordsWithBlanks(textPrompt);
      List<Parts> systemPartsContext = [];
      List<Parts> userPartsContext = [];
      if (isFirstTime) {
        systemPartsContext = getMultiTurnContext();
      }
      userPartsContext.add(Parts(text: textPrompt));

      if (chats.length > insertIndex) {
        systemPartsContext = getMultiTurnContext();
        int rem = chats.length % 7;
        if (rem == 0) {
          chats.add(Content(role: 'model', parts: systemPartsContext));
          pp('$mm ... System Context inserted  -- chats: ${chats.length}');
        }
      }
      chats.add(Content(role: 'user', parts: userPartsContext));
      _chatInputController.clear();
      _startAndListenToChatStream();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you 🍎🍎🍎',
          context: context);
    }
  }

  late String textPrompt;
  int chatStartCount = 0;

  DioUtil dioUtil = GetIt.instance<DioUtil>();

  int totalTokens = 0;
  Future _countTokens(
      {required String prompt,
      required List<String> systemStrings}) async {

    var sb = StringBuffer();
    for (var element in systemStrings) {
      sb.write('$element\n');
    }
    sb.write(prompt);

    var tokens = await
    gemini.countTokens(sb.toString(),modelName: 'gemini-pro');
    pp('$mm token response,🍎🍎 tokens: $tokens ... will write TokensUsed');
  }

  List<String> systemStrings = [];

  void _addTokensUsed() {
    try {
      var sb = StringBuffer();
      for (var content in chats) {
            if (content.role == 'user') {
              sb.write(content.parts?.first.text);
              sb.write('\n');
            }
          }
      // _countTokens(prompt: sb.toString(), systemStrings: systemStrings);
    } catch (e, s) {
      pp("ERROR counting tokens: $e $s");
    }
  }
  Future<void> _startAndListenToChatStream() async {
    pp('$mm _startAndListenToChatStream ...... 🍎🍎🍎🍎🍎🍎🍎🍎🍎 ');

    try {
      setState(() {
        _busy = true;
      });

      gemini.streamChat(
          chats,
          generationConfig: GenerationConfig(temperature: 0.0),
          modelName: ChatbotEnvironment.getGeminiModel())
          .listen((candidates) async {
        pp("\n\n$mm gemini.streamChat fired!: chats: ${chats.length} turnNumber: $turnNumber"
            " 🍎🍎🍎🍎🍎🍎🍎🍎🍎--------->");
        turnNumber++;
        loading = false;
        if (chats.isNotEmpty && chats.last.role == candidates.content?.role) {
          chats.last.parts!.last.text =
              '${chats.last.parts!.last.text}${candidates.output}';
        } else {
          chats.add(
              Content(role: 'model', parts: [Parts(text: candidates.output)]));
        }
        setState(() {
          _busy = false;
        });
        pp('$mm ... added to chats, now we have ${chats.length} chats. '
            '💜💜 ');
      });
    } catch (e, s) {
      pp('$mm ERROR: $e - $s');
    }
  }

  Widget chatItem(BuildContext context, int index) {
    final Content content = chats[index];
    var text = content.parts?.lastOrNull?.text ??
        'Sgela cannot help with your request. Try changing it ...';
    text = modifyString(text);
    bool isLatex = false;
    isLatex = isValidLaTeXString(text);
    String role = 'You';
    if (content.role == 'model') {
      role = 'SgelaAI';
    }

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
                child: LaTexViewer(
                  text: text,
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
      color:
          content.role == 'model' ? Colors.blue.shade800 : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            Card(
              elevation: 8,
              color: content.role == 'model'
                  ? Colors.blue.shade800
                  : Colors.transparent,
              child: Markdown(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  data: content.parts?.lastOrNull?.text ??
                      'Sgela cannot help with your request. Try changing it ...'),
            ),
          ],
        ),
      ),
    );
  }

  String modifyString(String input) {
    return input.replaceAll('**', '\n');
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
        leading: IconButton(onPressed: (){
          // _addTokensUsed();
          Navigator.of(context).pop();
          _addTokensUsed();
        }, icon: Platform.isAndroid? const Icon(Icons.arrow_back):const Icon(Icons.arrow_back_ios) ,),
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
                    style: myTextStyle(context, Theme.of(context).primaryColor,
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
              icon: Icon(Icons.share, color: Theme.of(context).primaryColor)),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                    child: chats.isNotEmpty
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: bd.Badge(
                              badgeContent: Text('${chats.length}'),
                              position:
                                  bd.BadgePosition.topEnd(top: -16, end: -8),
                              badgeStyle: const bd.BadgeStyle(
                                padding: EdgeInsets.all(12.0),
                              ),
                              onTap: () {
                                pp('$mm badge tapped, scroll up or down');
                              },
                              child: SingleChildScrollView(
                                reverse: true,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListView.builder(
                                    itemBuilder: chatItem,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: chats.length,
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
}
