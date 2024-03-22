import 'dart:async';

import 'package:edu_chatbot/local_util/functions.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/assistant_data_openai/message.dart';
import 'package:sgela_services/data/assistant_data_openai/question/assistant_question.dart';
import 'package:sgela_services/data/assistant_data_openai/run.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:get_it/get_it.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OpenAiAssistantQuestions extends StatefulWidget {
  const OpenAiAssistantQuestions({super.key, required this.questions, this.threadId, this.assistantId});

  final List<AssistantQuestion> questions;
  final String? threadId, assistantId;

  @override
  OpenAiAssistantQuestionsState createState() =>
      OpenAiAssistantQuestionsState();
}

class OpenAiAssistantQuestionsState extends State<OpenAiAssistantQuestions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '💛💛💛OpenAiAssistantQuestions 🍎🍎';
  OpenAIAssistantService assistantService =
  GetIt.instance<OpenAIAssistantService>();

  late Run run;

  late StreamSubscription<String> statusSubscription;
  late StreamSubscription<List<Message>> messageSubscription;

  List<Message> messages = [];
  bool _busy = false;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
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

      if (status == 'completed') {
        pp('\n\n\n$mm ... 🍎🍎🍎🍎🍎🍎 Thread run completed!! 🍎🍎🍎🍎🍎🍎\n\n\n');
      }
      if (mounted) {
        showToast(
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
            toastGravity: ToastGravity.TOP,
            message: 'SgelaAI status: $status',
            context: context);
      }
    });

    messageSubscription = assistantService.questionResponseStream.listen((mMessages) {
      pp('$mm ...questionResponseStream: Assistant messages arrived: ${mMessages.length}');
      _handleMessageArrived(mMessages);
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    });
  }

  Future<void> _runThread() async {
    if (widget.threadId == null) {
      return;
    }
    pp('$mm ... running thread .... : ${widget.threadId}');
    run = await assistantService.runThread(
        threadId: widget.threadId!, assistantId: widget.assistantId!);
    pp('$mm ... startPollingTimer .... run: ${run.id}');
    assistantService.startPollingTimer(widget.threadId!, run.id!, true);
  }

  Future _sendMessage(String text) async {
    if (widget.threadId == null) {
      return;
    }
    pp('\n\n$mm ... _sendMessage .... thread: ${widget.threadId} ');
    setState(() {
      _busy = true;
    });
     String textToSend = 'Please help me with: $text. Return your response in markdown format';
    try {
      var msg = await assistantService.createMessage(
          text: textToSend, threadId: widget.threadId!);
      pp('\n\n$mm ... createMessage .... '
          'response from Assistant, check to see if we need to add this to messages: 🍎 ${msg.toJson()} 🍎\n\n');
      messages.add(msg);
      _runThread();
    } catch (e, s) {
      pp('$mm $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
  }

  void _handleMessageArrived(List<Message> mMessages) {
    pp('$mm ... do nothing; message arrived via stream: ${mMessages.length},'
        ' should be handled by chat interface');
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
                Text(
                  'Exam Questions',
                  style: myTextStyle(context, Colors.teal, 28, FontWeight.w900),
                ),
                gapH32,
                Expanded(
                  child: ListView.builder(
                      itemCount: widget.questions.length,
                      itemBuilder: (ctx, index) {
                        var question = widget.questions.elementAt(index);
                        return QuestionWidget(
                          question: question,
                          onQuestion: (text) {
                            _sendMessage(text);
                          },
                        );
                      }),
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

class QuestionWidget extends StatelessWidget {
  const QuestionWidget(
      {super.key, required this.question, required this.onQuestion});

  final AssistantQuestion question;
  static const mm = '🥦🥦🥦 QuestionWidget';

  final Function(String) onQuestion;

  void _submitSubQuestion(String q) {
    pp('$mm ... submit sub question: 🤟🏾🤟🏾🤟🏾$q 🤟🏾');
    onQuestion(q);
  }

  void _submitQuestion(String questionText) {
    pp('$mm ... submit question: 🤟🏾🤟🏾🤟🏾$questionText 🤟🏾');
    onQuestion(questionText);
  }

  @override
  Widget build(BuildContext context) {
    StringBuffer desc = StringBuffer();
    if (question.questionText != null) {
      desc.write('${question.questionText}\n\n');
    }
    question.subQuestionText?.forEach((t) {
      desc.write('$t\n');
    });
    var height = 64.0;
    if (question.subQuestionText != null) {
      height = height + question.subQuestionText!.length * 40.0;
    }

    return GestureDetector(
      onTap: () {
        _submitQuestion(question.questionText!);
      },
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(question.questionText!),
              gapH16,
              SizedBox(
                height: height,
                child: ListView.builder(
                    itemCount: question.subQuestionText!.length,
                    itemBuilder: (_, index) {
                      var q = question.subQuestionText!.elementAt(index);
                      return SubQuestionWidget(
                        subQuestion: q,
                        onSubQuestionSelected: () {
                          _submitSubQuestion(q);
                        },
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubQuestionWidget extends StatelessWidget {
  const SubQuestionWidget(
      {super.key,
      required this.subQuestion,
      required this.onSubQuestionSelected});

  final String subQuestion;
  final Function() onSubQuestionSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSubQuestionSelected();
      },
      child: Card(
        elevation: 8,
        color: Colors.teal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(subQuestion),
        ),
      ),
    );
  }
}
