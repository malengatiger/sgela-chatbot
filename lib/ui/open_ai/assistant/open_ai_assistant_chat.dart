import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/local_util/functions.dart' as loc;
import 'package:edu_chatbot/local_util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/assistant_data_openai/assistant.dart';
import 'package:sgela_services/data/assistant_data_openai/message.dart';
import 'package:sgela_services/data/assistant_data_openai/run.dart';
import 'package:sgela_services/data/assistant_data_openai/thread.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/widgets/assistant_listener.dart';

import '../../gemini/widgets/chat_input_box.dart';
import 'open_ai_assistant_questions.dart';

class OpenAPIAssistantChat extends StatefulWidget {
  const OpenAPIAssistantChat(
      {super.key,
      this.threadId,
      this.assistant,
      required this.messages,
      required this.examLink});

  final String? threadId;
  final OpenAIAssistant? assistant;
  final List<Message> messages;
  final ExamLink examLink;

  @override
  OpenAPIAssistantChatState createState() => OpenAPIAssistantChatState();
}

class OpenAPIAssistantChatState extends State<OpenAPIAssistantChat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late StreamSubscription<String> statusSubscription;
  late StreamSubscription<List<Message>> messageSubscription;
  OpenAIAssistantService assistantService =
      GetIt.instance<OpenAIAssistantService>();
  List<Message> messages = [];
  Country? country;
  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  static const mm = '🔵🔵🔵🔵 OpenAPIAssistantChat  🔵🔵';
  Sponsoree? sponsoree;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    messages = widget.messages;
    _getData();
    _listen();
  }

  @override
  void dispose() {
    statusSubscription.cancel();
    messageSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _listen() {
    pp('$mm ... listening to Assistant result and status streams ....');

    statusSubscription = assistantService.statusStream.listen((status) {
      pp('$mm ... Assistant status arrived: $status');

      switch (status) {
        case 'queued':
          statusMessage = "Request is queued";
          break;
        case 'failed':
          statusMessage = "Request has failed";
          _busy = false;
          break;
        case 'expired':
          statusMessage = "Request has expired";
          _busy = false;
          break;
        case 'cancelling':
          statusMessage = "Request is being cancelled";
          break;
        case 'cancelled':
          statusMessage = "Request is cancelled";
          _busy = false;
          break;
        case 'in_progress':
          statusMessage = "SgelaAI is working ...";
          break;
        case 'completed':
          statusMessage = "Request is completed";
          _busy = false;
          pp('\n\n\n$mm ... 🍎🍎🍎🍎🍎🍎 Thread run completed!! 🍎🍎🍎🍎🍎🍎\n\n\n');
          break;
      }

      if (mounted) {
        setState(() {});
      }
    });
    messageSubscription =
        assistantService.questionResponseStream.listen((mMessages) {
      pp('$mm ...questionResponseStream: Assistant messages arrived: ${mMessages.length}');
      for (var msg in mMessages) {
        pp('$mm message: ${msg.toJson()}');
      }
      messages.add(mMessages.first);
      if (mounted) {
        setState(() {
          _busy = false;
        });
        _scrollToBottom();
      }
      if (activeThreadId != null) {
        assistantService.getTokens(
            sponsoree: sponsoree!,
            threadId: activeThreadId!, model: widget.assistant!.model!);
      }
    });
  }

  String statusMessage = '';
  bool _busy = false;

  _getData() async {
    pp('$mm ... getting data ...');
    setState(() {
      _busy = true;
    });
    try {
      organization = prefs.getOrganization();
      country = prefs.getCountry();
      sponsoree = prefs.getSponsoree();
    } catch (e) {
      pp(e);
      loc.showErrorDialog(context, '$e');
    }
    setState(() {
      _busy = false;
    });
  }

  TextEditingController textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Thread? newThread;
  Run? run;
  String? activeThreadId;

  void _sendMessage() async {
    setState(() {
      _busy = true;
    });
    try {
      if (textEditingController.text.isEmpty) {
        loc.showToast(
            message: 'Enter your query and try again', context: context);
        setState(() {
          _busy = false;
        });
        return;
      }
      var text = textEditingController.text;
      text = text.trim();
      pp('$mm  Sending Message: $text');
      Message? responseMsg;
      if (widget.threadId == null) {
        newThread = await assistantService.createThread();
        activeThreadId = newThread!.id!;
        responseMsg = await assistantService.createMessage(
            threadId: newThread!.id!, text: text);
        run = await assistantService.runThread(
            threadId: newThread!.id!, assistantId: widget.assistant!.id!);
      } else {
        activeThreadId = widget.threadId;
        responseMsg = await assistantService.createMessage(
            threadId: widget.threadId!, text: textEditingController.text);
        run = await assistantService.runThread(
            threadId: widget.threadId!, assistantId: widget.assistant!.id!);
      }
      messages.add(responseMsg);
      assistantService.startPollingTimer(
          widget.threadId == null ? newThread!.id! : widget.threadId!,
          run!.id!,
          false);
    } catch (e) {
      pp(e);
      if (mounted) {
        loc.showErrorDialog(context, '$e');
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (_) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  QuestionHeader(
                    examLink: widget.examLink,
                  ),
                  statusMessage.isEmpty
                      ? gapW8
                      : Card(
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  'SgelaAI Status:',
                                  style: loc.myTextStyleTiny(context),
                                ),
                                gapW8,
                                Text(
                                  statusMessage,
                                  style: loc.myTextStyleSmallBoldPrimaryColor(
                                      context),
                                ),
                              ],
                            ),
                          ),
                        ),
                  gapH16,
                  Expanded(
                    child: bd.Badge(
                      badgeContent: Text('${messages.length}'),
                      position: bd.BadgePosition.topEnd(top: -28.0, end: -2),
                      badgeStyle: const bd.BadgeStyle(
                        padding: EdgeInsets.all(12.0),
                        badgeColor: Colors.purple,
                      ),
                      child: ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            var msg = messages.elementAt(index);
                            return Card(
                                color: msg.role! == 'user'
                                    ? Colors.transparent
                                    : Colors.blue.shade700,
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: MarkdownBody(
                                        data: msg.content!.first.text!.value!),
                                  ),
                                ));
                          }),
                    ),
                  ),
                  _busy
                      ? gapW8
                      : SizedBox(
                          width: double.infinity,
                          child: ChatInputBox(
                            controller: textEditingController,
                            onSend: () {
                              _sendMessage();
                            },
                          ),
                        ),
                ],
              ),
            ),
            _busy
                ? const Positioned(
                    bottom: 8.0, left: 8.0, child: AssistantListener())
                : gapH8,
          ],
        );
      },
      tablet: (_) {
        return const Stack();
      },
      desktop: (_) {
        return const Stack();
      },
    );
  }
}
