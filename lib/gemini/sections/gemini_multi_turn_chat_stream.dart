import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/gemini/widgets/chat_input_box.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/ui/chat/latex_math_viewer.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';

import '../../util/functions.dart';

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
  var controller = TextEditingController();

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
      controller = TextEditingController(
          text: 'I need help with this subject: ${widget.subject?.title}');
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
    if (_examPageText != null && _examPageText!.isNotEmpty) {
      textPrompt = _examPageText!;
    } else {
      if (controller.text.isNotEmpty) {
        textPrompt = controller.text;
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
      if (isFirstTime) {
        //chats.add(Content(role: 'model', parts: systemPartsContext));
      }
      chats.add(Content(role: 'user', parts: userPartsContext));
      if (chats.length > insertIndex) {
        systemPartsContext = getMultiTurnContext();
        int index = (chats.length / 2) as int;
        chats.insert(index, Content(role: 'model', parts: systemPartsContext));
        insertIndex += 6;
        pp('$mm ... System Context inserted at index: $index -- chats: ${chats.length}');
      }
      controller.clear();
      loading = true;
      _startAndListenToChatStream();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you 🍎🍎🍎', context: context);
    }
  }

  late String textPrompt;
  int chatStartCount = 0;

  Future<void> _startAndListenToChatStream() async {
    pp('$mm _startAndListenToChatStream ...... 🍎🍎🍎🍎🍎🍎🍎🍎🍎 ');

    try {
      // var tokens = await gemini
      //     .countTokens(textPrompt)
      //     .catchError((e) => pp('countTokens error : $e'));
      // pp('$mm ai tokens for prompt: $tokens');

      gemini.streamChat(chats).listen((candidates) {
            pp("\n\n$mm gemini.streamChat fired!: chats: ${chats.length} turnNumber: $turnNumber"
                " 🍎🍎🍎🍎🍎🍎🍎🍎🍎--------->");
            turnNumber++;
            loading = false;
            setState(() {
              if (chats.isNotEmpty && chats.last.role == candidates.content?.role) {
                chats.last.parts!.last.text =
                    '${chats.last.parts!.last.text}${candidates.output}';
              } else {
                chats.add(
                    Content(role: 'model', parts: [Parts(text: candidates.output)]));
              }
            });
            pp('$mm ... added to chats, now we have ${chats.length} chats. '
                '💜💜 turnNumber: $turnNumber');
            for (var value in chats) {
              myPrettyJsonPrint(value.toJson());
            }
          });
    } catch (e,s) {
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
              color: content.role == 'model' ? Colors.blue.shade800 : Colors.transparent,

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
                            child: SingleChildScrollView(
                              reverse: true,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  itemBuilder: chatItem,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: chats.length,
                                  reverse: false,
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
                      controller: controller,
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
            )
          ],
        ),
      ),
    ));
  }
}
