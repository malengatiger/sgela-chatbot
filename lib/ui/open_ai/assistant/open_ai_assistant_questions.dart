import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/local_util/functions.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/assistant_data_openai/message.dart';
import 'package:sgela_services/data/assistant_data_openai/question/assistant_question.dart';
import 'package:sgela_services/data/assistant_data_openai/run.dart';
import 'package:sgela_services/data/assistant_data_openai/thread.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_shared_widgets/widgets/assistant_listener.dart';

class OpenAiAssistantQuestions extends StatefulWidget {
  const OpenAiAssistantQuestions(
      {super.key,
      required this.questions,
      this.threadId,
      this.assistantId,
      required this.onMessagesReceived,
      required this.examLink});

  final List<AssistantQuestion> questions;
  final String? threadId, assistantId;
  final Function(List<Message>) onMessagesReceived;
  final ExamLink examLink;

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

    messageSubscription =
        assistantService.questionResponseStream.listen((mMessages) {
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

  Thread? newThread;
  String? threadId;

  Future _sendMessage(String text) async {
    setState(() {
      _busy = true;
    });

    try {
      if (widget.threadId == null) {
        newThread = await assistantService.createThread();
        if (newThread != null) {
          threadId = newThread!.id!;
        }
      } else {
        threadId = widget.threadId!;
      }
      String textToSend =
          'Please help me with the following question: $text. \nReturn your response in markdown format';
      pp('\n\n$mm ... _sendMessage .... thread: ${widget.threadId} textToSend: $textToSend');

      var msg = await assistantService.createMessage(
          text: textToSend, threadId: widget.threadId!);
      pp('\n\n$mm ... createMessage .... '
          'response from Assistant, check to see if we need to add this to messages: 🍎 ${msg.toJson()} 🍎\n\n');
      //messages.add(msg);
      _runThread();
    } catch (e, s) {
      pp('$mm $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
  }

  void _handleMessageArrived(List<Message> mMessages) {
    pp('$mm ... _handleMessageArrived: '
        'do nothing; message arrived via stream: ${mMessages.length},'
        ' should be handled by chat interface');
    setState(() {
      _busy = false;
    });
    widget.onMessagesReceived(mMessages);
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
                  style: myTextStyle(context, Colors.teal, 20, FontWeight.w900),
                ),
                gapH8,
                QuestionHeader(
                  examLink: widget.examLink,
                ),
                // gapH4,
                Expanded(
                  child: bd.Badge(
                    badgeContent: Text('${widget.questions.length}'),
                    position: bd.BadgePosition.topEnd(end: 12, top: -2),
                    badgeStyle: const bd.BadgeStyle(
                      elevation: 12,
                      padding: EdgeInsets.all(12.0),
                      badgeColor: Colors.pink,
                    ),
                    child: ListView.builder(
                        itemCount: widget.questions.length,
                        itemBuilder: (ctx, index) {
                          var question = widget.questions.elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: QuestionWidget(
                              question: question,
                              onQuestion: (text) {
                                _sendMessage(text);
                              },
                            ),
                          );
                        }),
                  ),
                ),
              ],
            ),
            _busy
                ? const Positioned(
                    bottom: 2,
                    left: 16,
                    child: AssistantListener(),
                  )
                : gapH16,
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
    var height = 48.0;
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
          padding: const EdgeInsets.all(16.0),
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
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
          child: Text(subQuestion),
        ),
      ),
    );
  }
}

class QuestionHeader extends StatelessWidget {
  final ExamLink examLink;

  const QuestionHeader({super.key, required this.examLink});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Column(
        children: [
          Text('${examLink.subject?.title}'),
          gapH8,
          Text(
            '${examLink.documentTitle}',
            style: myTextStyleTiny(context),
          ),
          gapH4,
          Text(
            '${examLink.title}',
            style: myTextStyleSmall(context),
          )
        ],
      ),
    );
  }
}
