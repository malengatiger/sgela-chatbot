import 'dart:async';
import 'dart:io';

import 'package:edu_chatbot/local_util/functions.dart';
import 'package:edu_chatbot/ui/gemini/widgets/chat_input_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/groq/groq_chat_response.dart';
import 'package:sgela_services/data/groq/groq_models.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:sgela_services/data/tokens_used.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/groq_service.dart';
import 'package:sgela_services/services/local_data_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/util/styles.dart' as styles;
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';
import 'package:badges/badges.dart' as bd;
class GroqChat extends StatefulWidget {
  const GroqChat(
      {super.key, this.examLink, this.subject, this.examPageContents});

  final ExamLink? examLink;
  final Subject? subject;
  final List<ExamPageContent>? examPageContents;

  @override
  State<GroqChat> createState() => GroqChatState();
}

class GroqChatState extends State<GroqChat> {
  static const mm = '🍐🍐🍐🍐 GroqChat 🍐';

  bool _busy = false;

  bool get loading => _busy;
  int turnNumber = 0;

  set loading(bool set) => setState(() => _busy = set);
  final List<Message> chats = [];

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
  final List<Message> _messages = [];
  String? subject;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _getPageContents() async {
    sponsoree = prefs.getSponsoree();
    var sb = StringBuffer();
    if (widget.subject != null) {
      _chatInputController = TextEditingController(
          text: 'I need help with this subject: ${widget.subject?.title}');
      subject = widget.subject?.title;
    }
    if (widget.examLink != null) {
      _chatInputController = TextEditingController(
          text:
              'I need help with this subject: ${widget.examLink!.subject?.title}');
      subject = widget.examLink!.subject?.title;
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
      _chatInputController = TextEditingController(text: _examPageText!);
    }
    _handleInputText();
    setState(() {});
  }

  void _handleInputText() {
    textPrompt = _chatInputController.text;
    if (textPrompt.isNotEmpty) {
      textPrompt = _replaceKeywordsWithBlanks(textPrompt);
      _chatInputController.clear();
      _sendInitialRequest();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you 🍎🍎🍎',
          context: context);
    }
  }

  String textPrompt = 'Hello!';
  GroqService groqService = GetIt.instance<GroqService>();

  static const xx = '🍎🍎🍎';

  Future<void> _sendInitialRequest() async {
    pp('\n\n\n$mm _startAndListenToChatStream ...... $xx$xx$xx $textPrompt');
    try {
      _messages.add(
        Message(role: 'user', content: textPrompt),
      );
      setState(() {
        _busy = true;
      });

      List<Message> messagesToSend = [
        Message(
            role: 'system',
            content: 'You are a Tutor and exam Assistant for $subject '
                'and you return your responses in markdown format'),
        Message(role: 'user', content: textPrompt),
      ];
      pp('$mm ... _sendInitialRequest: calling groqService.sendGroqRequests'
          ' ... $xx messagesToSend: ${messagesToSend.length}');
      var responses =
          await groqService.sendGroqRequests(messages: messagesToSend);
      chatResponse = responses[0];
      _handleResponse();
      _printMessages();
      _printUsage();
    } catch (e, s) {
      pp('$mm ERROR: $e - $s');
    }
    setState(() {
      _busy = false;
    });
  }

  // void close() {
  //   _subscription.cancel();
  // }

  void _addTokensUsed() {}

  Future _submitRequest() async {
    try {
      _messages.add(Message(role: 'user', content: _chatInputController.text));
      setState(() {
        _busy = true;
      });

      pp('$mm ... calling groqService.sendGroqRequests ... $xx messages: ${_messages.length}');
      var responses = await groqService.sendGroqRequests(messages: _messages);
      chatResponse = responses[0];
      _handleResponse();
      _printMessages();
      _printUsage();
    } catch (e, s) {
      pp('$mm ERROR: $e - $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  void _handleResponse() {
    if (chatResponse!.choices![0].finishReason == 'stop') {
      pp('\n\n\n$mm ... chatResponse is GOOD.  🔵🔵finishReason: ${chatResponse!.choices![0].finishReason} 🔵🔵');
      pp('$mm ... groqService.sendGroqRequests: response:  🔵🔵${chatResponse!.toJson()}  🔵🔵');
      _messages.add(Message(
          role: 'assistant',
          content: chatResponse?.choices?[0].message?.content));
      scrollToIndex(_messages.length - 1);
    } else {
      if (mounted) {
        showErrorDialog(
            context, 'Something went wrong. Please try again later. 😞😞😞');
      }
    }
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0, // Scroll to the top of the list
      duration: const Duration(milliseconds: 500),
      // Adjust the duration as needed
      curve: Curves.easeInOut, // Adjust the curve as needed
    );
  }

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      // Scroll to the bottom of the list
      duration: const Duration(milliseconds: 500),
      // Adjust the duration as needed
      curve: Curves.easeInOut, // Adjust the curve as needed
    );
  }

  void scrollToIndex(int index) {
    final double itemExtent = _scrollController.position.viewportDimension;
    final double targetOffset = index * itemExtent;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  GroqChatResponse? chatResponse;
  Sponsoree? sponsoree;

  Future<void> _printUsage() async {
    pp('\n\n\n$mm ... 🔶🔶🔶🔶 Groq Token Usage ...');
    if (chatResponse != null) {
      if (chatResponse!.usage != null && sponsoree != null) {
        pp('$mm ... 🔶🔶🔶🔶Groq Response Usage: 🔶🔶🔶🔶 '
            '${chatResponse!.usage!.toJson()} 🔶🔶');
        TokensUsed tu = TokensUsed(
            organizationId: sponsoree!.organizationId!,
            sponsoreeId: sponsoree!.id!,
            date: DateTime.now().toUtc().toIso8601String(),
            sponsoreeName: sponsoree!.sgelaUserName,
            organizationName: sponsoree!.organizationName,
            model: modelMixtral,
            promptTokens: chatResponse!.usage!.promptTokens,
            completionTokens: chatResponse!.usage!.completionTokens,
            totalTokens: chatResponse!.usage!.totalTokens);

        await firestoreService.addTokensUsed(tu);
      }
    }
  }

  Future<void> _printMessages() async {
    pp('$mm ... ❎❎❎ current Groq Messages: ${_messages.length}');
    for (var m in _messages) {
      pp('$mm ... ❎❎❎ Groq Message: ❎ role: ${m.role}  ❎ content: ${m.content}');
    }
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

  List<GroqBag> bags = [];
  final ScrollController _scrollController = ScrollController();
  final ScrollController _mdScrollController = ScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  String selectedText = '';

  void onSelectionChanged(
      String? text, TextSelection selection, SelectionChangedCause? cause) {
    if (text != null &&
        selection.baseOffset != -1 &&
        selection.extentOffset != -1) {
      final String selectedText =
          text.substring(selection.baseOffset, selection.extentOffset);
      setState(() {
        this.selectedText = selectedText;
      });
    }
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
                        18, FontWeight.w900),
                  ),
            gapW8,
            Text(
              'Groq',
              style: myTextStyleTiny(context),
            ),
            gapW32,
            bd.Badge(
              badgeContent: Text('${_messages.length}'),
              badgeStyle: const bd.BadgeStyle(
                  padding: EdgeInsets.all(8.0),
                  badgeColor: Colors.red
              ),
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
                  child: ListView.builder(
                      itemCount: _messages.length,
                      controller: _scrollController,
                      itemBuilder: (_, index) {
                        var msg = _messages[index];
                        if (msg.role == 'assistant') {
                          return Card(
                            elevation: 8,
                            color: Colors.blue.shade700,
                            child: SizedBox(
                              height: _calculateSizedBoxHeight(msg.content!),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'SgelaAI Assistant',
                                          style:
                                              styles.myTextStyleMediumLarge(
                                                  context, 16),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Markdown(
                                        data: msg.content!,
                                        selectable: true,
                                        onSelectionChanged:
                                            (string, sel, cause) {
                                          onSelectionChanged(
                                              string, sel, cause);
                                        },
                                        // controller: _mdScrollController,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(left:24.0, right:24.0, top:8, bottom:8),
                            child: Card(
                                elevation: 16.0,
                                color: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'You',
                                            style:
                                                styles.myTextStyleMediumLarge(
                                                    context, 16),
                                          ),
                                        ],
                                      ),
                                      Text(msg.content!),
                                    ],
                                  ),
                                )),
                          );
                        }
                      }),
                ),
                ChatInputBox(
                  controller: _chatInputController,
                  onSend: () {
                    _submitRequest();
                  },
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
                        width: 200,
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

  double _calculateSizedBoxHeight(String text) {
    final textLength = text.length;
    const lineHeight =
        22.0; // Adjust this value based on your desired line height
    const padding = 8.0; // Adjust this value based on your desired padding

    final lines = (textLength / 32)
        .ceil(); // Adjust the divisor based on your desired line length

    var height = (lines * lineHeight) + (2 * padding);
    pp('$mm ... height: $height from text: ${text.length}');
    return height;
  }
}

class GroqBag {
  late GroqRequest groqRequest;
  GroqChatResponse? groqChatResponse;

  GroqBag({required this.groqRequest, this.groqChatResponse});
}
