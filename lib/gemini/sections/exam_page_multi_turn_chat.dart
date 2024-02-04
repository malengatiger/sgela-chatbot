import 'dart:io';

import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/gemini/widgets/chat_input_box.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/ui/chat/math_viewer.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/powered_by.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';

import '../../util/functions.dart';

class ExamPageMultiTurnChat extends StatefulWidget {
  const ExamPageMultiTurnChat(
      {super.key, required this.examLink, required this.examPageContents});

  final ExamLink examLink;
  final List<ExamPageContent> examPageContents;

  // @override
  State<ExamPageMultiTurnChat> createState() => ExamPageMultiTurnChatState();
}

class ExamPageMultiTurnChatState extends State<ExamPageMultiTurnChat> {
  static const mm = '🍐🍐🍐🍐 ExamPageMultiTurnChat 🍐';

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
    // _showModels();
    _handleImages();
  }

  ExamPageContent? examPageContent;
  int imageCount = 0;

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

  _handleImages() {
    for (var value in widget.examPageContents) {
      if (value.pageIndex == 0) {
        continue;
      }
      if (value.pageImageUrl != null) {
        imageCount++;
      }
    }
    pp('$mm ... images in selected pages: $imageCount');
    if (imageCount > 0) {
      _navigateToTextAndImageChat();
    } else {
      _buildPromptAndStartQuery();
    }
  }

  Future _navigateToTextAndImageChat() async {
    pp('$mm ... _navigateToTextAndImageChat; images: $imageCount');

    final file = File('assets/img.png');
    gemini.textAndImage(
        text: "What is this picture?", /// text
        images: [file.readAsBytesSync()] /// list of images
    )
        .then((value) => pp(value?.content?.parts?.last.text ?? ''))
        .catchError((e) => pp('textAndImageInput error $e'));
  }

  _setContext() {

    gemini.chat([
      Content(parts: [
        Parts(text: 'My name is SgelaAI and I am a super tutor who knows everything. '
            '\nI am here to help you study and practice for all your high school '
            'and college courses and subjects')],
          role: 'model'),
      Content(parts: [
        Parts(text: 'I answer questions and solve problems that relate to the subject provided.')],
          role: 'model'),
      Content(parts: [
        Parts(text: 'Help me research, prepare and study')],
          role: 'user'),
    ])
        .then((value) => pp(value?.output ?? 'without output'))
        .catchError((e) => pp('chat error: $e'));
  }
  _buildPromptAndStartQuery() {
    var sb = StringBuffer();
    sb.write('Answer the question or solve the problem in the text below. \n');
    sb.write('Think step by step. \n');
    sb.write(
        'Separate questions or problems with headings where appropriate '
            'otherwise use blank lines between questions. \n');

    for (var pageContent in widget.examPageContents) {
      sb.write('${pageContent.text} \n');
    }
    Parts parts = Parts(text: sb.toString());
    List<Parts> systemPromptContext = [];
    List<Parts> userPrompt = [];
    userPrompt.add(parts);

    if (turnNumber == 0) {
      systemPromptContext = getMultiTurnContext();
    }

    systemPromptContext.add(Parts(text: sb.toString()));

    chats.add(Content(role: 'system', parts: systemPromptContext));
    chats.add(Content(role: 'user', parts: userPrompt));
    controller.clear();
    loading = true;
    Future.delayed(const Duration(milliseconds: 100),(){
      _startAndListenToChatStream();
    });
  }

  void _handleQueryText() {
    if (controller.text.isNotEmpty) {
      queryText = controller.text;
      List<Parts> partsContext = [];
      if (turnNumber == 0) {
        partsContext = getMultiTurnContext();
      }
      partsContext.add(Parts(text: queryText));
      chats.add(Content(role: 'user', parts: partsContext));
      controller.clear();
      loading = true;
      _startAndListenToChatStream();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you', context: context);
    }
  }

  late String queryText;

  Future<void> _startAndListenToChatStream() async {
    pp('$mm _startAndListenToChatStream ............');

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
              LaTexViewer(
                text: text,
                showHeader: false,
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

  final List<ExamPageContent> selectedPageContents = [];

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
      body: SizedBox(
        height: double.infinity,
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
                        : const Center(
                            child: Text('Say something to SgelaAI'))),
                ChatInputBox(
                  controller: controller,
                  onSend: () {
                    _handleQueryText();
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
