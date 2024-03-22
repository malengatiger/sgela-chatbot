import 'dart:async';

import 'package:edu_chatbot/local_util/functions.dart' as loc;
import 'package:edu_chatbot/local_util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/assistant_data_openai/message.dart';
import 'package:sgela_services/data/assistant_data_openai/run.dart';
import 'package:sgela_services/data/assistant_data_openai/thread.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

import '../../gemini/widgets/chat_input_box.dart';

class OpenAPIAssistantChat extends StatefulWidget {
  const OpenAPIAssistantChat({super.key, this.threadId, this.assistantId});

  final String? threadId, assistantId;

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

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
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
          if (mounted) {
            loc.showToast(
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
                toastGravity: ToastGravity.TOP,
                message: 'SgelaAI has completed your request',
                context: context);
          }
          break;
      }

      if (mounted) {
        setState(() {});
      }
    });

    messageSubscription =
        assistantService.questionResponseStream.listen((mMessages) {
      pp('$mm ...questionResponseStream: Assistant messages arrived: ${mMessages.length}');
      messages.addAll(mMessages);
      if (mounted) {
        setState(() {
          _busy = false;
        });
        _scrollToBottom();
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
  void _sendMessage() async {
    setState(() {
      _busy = true;
    });
    try {
      // organization = prefs.getOrganization();
      // country = prefs.getCountry();
      if (textEditingController.text.isEmpty) {
        return;
      }
      if (widget.threadId == null) {
        newThread = await assistantService.createThread();
        run = await assistantService.runThread(threadId: newThread!.id!, assistantId: widget.assistantId!);
        assistantService.createMessage(
            threadId: newThread!.id!, text: textEditingController.text);
      } else {
        assistantService.createMessage(
            threadId: widget.threadId!, text: textEditingController.text);
      }
    } catch (e) {
      pp(e);
      loc.showErrorDialog(context, '$e');
    }
    setState(() {
      _busy = false;
    });
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                statusMessage.isEmpty? gapW8: Card(
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
                          style: loc.myTextStyleSmallBoldPrimaryColor(context),
                        ),
                      ],
                    ),
                  ),
                ),

                gapH16,
                Expanded(
                  child: ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (_, index) {
                        var msg = messages.elementAt(index);
                        Color color = Colors.teal;
                        if (msg.role == 'user') {
                          color = Colors.transparent;
                        }
                        return Card(
                          color: color,
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(msg.content!.first.text!.value!),
                          ),
                        );
                      }),
                ),

                _busy
                    ? gapW8
                    : SizedBox(width: double.infinity,
                      child: ChatInputBox(
                          controller: textEditingController,
                          onSend: () {
                            _sendMessage();
                          },
                        ),
                    ),
              ],
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
    );
  }
}
