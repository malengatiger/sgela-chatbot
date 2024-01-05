import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

import '../data/exam_link.dart';
import '../data/subject.dart';
import '../repositories/repository.dart';
import '../services/chat_service.dart';
import '../util/functions.dart';
import 'markdown_widget.dart';

class TextChat extends StatefulWidget {
  const TextChat(
      {super.key,
      required this.examLink,
      required this.repository,
      required this.chatService,
      required this.subject});

  final ExamLink examLink;
  final Repository repository;
  final ChatService chatService;
  final Subject subject;

  @override
  TextChatState createState() => TextChatState();
}

class TextChatState extends State<TextChat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  TextEditingController textEditingController = TextEditingController();

  bool isMarkDown = false;
  String copiedText = '';
  String responseText = 'The response text will show up right here. ';
  static const mm = '🍎🍎🍎TextChat 🍎';
  bool busy = false;
  int chatCount = 0;
  List<String> responseHistory = [];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    timer.cancel();
    super.dispose();
  }

  Future<void> _sendChatPrompt() async {
    String prompt = textEditingController.value.text;
    var promptContext = getPromptContext();
    if (chatCount == 0) {
      prompt = '$promptContext \nSubject: ${widget.subject.title}. $prompt';
    } else {
      prompt = '$promptContext $prompt';
    }
    pp('$mm .............. sending chat prompt: \n🍎🍎$prompt 🍎🍎\n');

    _startTimer();
    setState(() {
      busy = true;
    });
    try {
      var resp = await widget.chatService.sendChatPrompt(prompt);
      pp('$mm ....... chat response: \n$resp\n');
      responseText += '\n\n$resp$responseText';
      bool yesMarkdown = isMarkdownFormat(responseText);
      bool yesLaTex = isValidLaTeXString(responseText);
      pp('$mm ....... chat response, 🍎yesMarkdown: $yesMarkdown 🍎yesLaTex: $yesLaTex');

      if (yesMarkdown) {
        if (yesLaTex) {
          isMarkDown = false;
          responseText = replaceTextInPlace(responseText);
        } else {
          isMarkDown = true;
        }
      } else {
        isMarkDown = false;
      }
      chatCount++;
      responseHistory.add(resp);
    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, 'Error: $e');
      }
    }
    timer.cancel();
    setState(() {
      busy = false;
    });
  }

  late Timer timer;
  String elapsed = '00:00:00';

  void _startTimer() {
    int timeInSeconds = 0; // Replace this with the actual time in seconds

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeInSeconds++;
      elapsed = getFormattedTime(timeInSeconds: timeInSeconds);
      if (mounted) {
        setState(() {
          // Update the UI with the elapsed time
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('SgelaAI Chatbot'),
              actions: [
                IconButton(onPressed: (){
                  pp('$mm ... share the response ... 🍎');
                }, icon: const Icon(Icons.share))
              ],
            ),
            backgroundColor: Colors.brown[100],
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: bd.Badge(
                position: bd.BadgePosition.topEnd(end: 8, top: -8),
                badgeStyle: const bd.BadgeStyle(
                  elevation: 16,
                  padding: EdgeInsets.all(12.0),
                ),
                badgeContent: Text(
                  '${(responseText.length / 1024).toStringAsFixed(0)}K',
                  style:
                      myTextStyle(context, Colors.white, 16, FontWeight.normal),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: isMarkDown
                          ? MarkdownWidget(text: responseText)
                          : Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TeXView(
                                  renderingEngine:
                                      const TeXViewRenderingEngine.katex(),
                                  child: TeXViewColumn(
                                    children: [
                                      TeXViewDocument(responseText),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Card(
                        elevation: 8,
                        child: Form(
                            child: Column(
                          children: [
                            gapH16,
                            TextFormField(
                              controller: textEditingController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  label: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Text(
                                        'SgelaAI question should be entered here'),
                                  )),
                            ),
                            gapH16,
                            busy
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 6,
                                          backgroundColor: Colors.pink,
                                        ),
                                      ),
                                      gapW16,
                                      gapW16,
                                      Text(
                                        elapsed,
                                        style: myTextStyle(context, Colors.blue,
                                            14, FontWeight.bold),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${responseHistory.length}',
                                        style: myTextStyle(
                                            context,
                                            Colors.grey[400]!,
                                            24,
                                            FontWeight.w900),
                                      ),
                                      gapW16,
                                      gapW16,
                                      ElevatedButton.icon(
                                          style: const ButtonStyle(
                                            elevation:
                                                MaterialStatePropertyAll(16),
                                          ),
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            _sendChatPrompt();
                                          },
                                          icon: const Icon(Icons.send),
                                          label: const Text('Send to SgelaAI')),
                                    ],
                                  ),
                            gapH16,
                          ],
                        ))),
                  ],
                ),
              ),
            )));
  }
}
