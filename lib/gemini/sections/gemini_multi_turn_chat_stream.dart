import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/gemini/widgets/chat_input_box.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/chat/latex_math_viewer.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';

import '../../util/functions.dart';

class GeminiMultiTurnStreamChat extends StatefulWidget {
  const GeminiMultiTurnStreamChat(
      {super.key, this.examLink, this.subject});

  final ExamLink? examLink;
  final Subject? subject;

  @override
  State<GeminiMultiTurnStreamChat> createState() => GeminiMultiTurnStreamChatState();
}

class GeminiMultiTurnStreamChatState extends State<GeminiMultiTurnStreamChat> {
  static const mm = '🍐🍐🍐🍐 GeminiMultiTurnStreamChat 🍐';

  final controller = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _showModels();
    _getPageContents();
  }
  List<ExamPageContent> examPageContents = [];
  ExamPageContent? examPageContent;
  _getPageContents() async {
    if (widget.examLink != null) {
      examPageContents = await localDataService.getExamPageContents(widget.examLink!.id!);
      if (examPageContents.isEmpty) {
        examPageContents = await firestoreService.getExamPageContents(widget.examLink!.id!);
      }
    }
    pp('$mm ... ${examPageContents.length} examPageContents found');
  }

  _showModels() async {
    pp('$mm ... show all the AI models available');
    await gemini
        .listModels()
        .then((models) => () {
              for (var value in models) {
                pp('$mm AI model ....... ${value.toJson()}');
              }
            })
        .catchError((e) => pp('$mm listModels ERROR: $e'));

    pp('$mm ... show the AI model in use now');

    await gemini
        .info(model: 'gemini-pro')
        .then((info) => pp('$mm gemini.info: ${info.toJson()}'))
        .catchError((e) => pp('$mm gemini.info: $e'));
  }

  _getFormattingPrompt() {
      var sb = StringBuffer();
      sb.write('Format the following text and improve the look and readability of the output text ');
      if (examPageContent != null) {
        searchedText = '${sb.toString()}\n${examPageContent!.text!}';
        List<Parts> partsContext = [];
        if (turnNumber == 0) {
          partsContext = getMultiTurnContext();
        }
        partsContext.add(Parts(text: searchedText));
        chats.add(Content(role: 'user', parts: partsContext));
        controller.clear();
        loading = true;
        _startAndListenToChatStream();
      } else {
        showToast(message: 'Say something, I did not quite hear you', context: context);
      }
  }

  void _handleInputText() {
    if (controller.text.isNotEmpty) {
      searchedText = controller.text;
      List<Parts> partsContext = [];
      if (turnNumber == 0) {
        partsContext = getMultiTurnContext();
      }
      partsContext.add(Parts(text: searchedText));
      chats.add(Content(role: 'user', parts: partsContext));
      controller.clear();
      loading = true;
      _startAndListenToChatStream();
    } else {
      showToast(message: 'Say something, I did not quite hear you', context: context);
    }
  }

  late String searchedText;

  Future<void> _startAndListenToChatStream() async {
    pp('$mm _startAndListenToChatStream ......  ');
    var tokens = await gemini
        .countTokens(searchedText)
        .then((value) => pp('$mm value: $value'))
        .catchError((e) => pp('countTokens error : $e'));
    pp('$mm ai tokens: $tokens');
    gemini.streamChat(chats).listen((candidates) {
      pp("$mm gemini.streamChat fired!: chats: ${chats.length} "
          "------------------------------->>>");
      pp('$mm ${candidates.output}');
      turnNumber++;
      loading = false;
      setState(() {
        if (chats.isNotEmpty && chats.last.role == candidates.content?.role) {
          chats.last.parts!.last.text =
          '${chats.last.parts!.last.text}${candidates.output}';
        } else {
          chats.add(
              Content(role: 'model', parts: [Parts(text: candidates.output)]));
          pp('$mm ... added to chats, now we have ${chats.length} chats. turnNumber: $turnNumber');
        }
      });
    });
  }

  Widget chatItem(BuildContext context, int index) {
    final Content content = chats[index];
    var  text = content.parts?.lastOrNull?.text ??
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
        color:
        role == 'SgelaAI' ? Colors.blue.shade800 : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role),
              LaTexViewer(text: text, showHeader: false,),
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
            Markdown(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                data: content.parts?.lastOrNull?.text ??
                    'Sgela cannot help with your request. Try changing it ...'),
          ],
        ),
      ),
    );
  }
  String modifyString(String input) {
    return input.replaceAll('**', '\n');
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Chat with ',
              style: myTextStyleSmall(context),
            ),
            gapW8,
            Text(
              'SgelaAI',
              style: myTextStyle(
                  context, Theme.of(context).primaryColor, 24, FontWeight.w900),
            ),
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
      body: SizedBox(height: double.infinity,
        child: Stack(
          children: [
            Column(
              children: [
                const SponsoredBy(),

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
                        : const Center(child: Text('Say something to SgelaAI'))),
                ChatInputBox(
                  controller: controller,
                  onSend: () {
                    _handleInputText();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    ));
  }

}
