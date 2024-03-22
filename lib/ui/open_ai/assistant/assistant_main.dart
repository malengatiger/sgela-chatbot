import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_chatbot/local_util/functions.dart' as fun;
import 'package:edu_chatbot/local_util/functions.dart';
import 'package:edu_chatbot/ui/open_ai/assistant/open_ai_assistant_chat.dart';
import 'package:edu_chatbot/ui/open_ai/assistant/open_ai_assistant_document.dart';
import 'package:edu_chatbot/ui/open_ai/assistant/open_ai_assistant_questions.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/assistant_data_openai/assistant.dart';
import 'package:sgela_services/data/assistant_data_openai/message.dart';
import 'package:sgela_services/data/assistant_data_openai/question/assistant_question.dart';
import 'package:sgela_services/data/assistant_data_openai/run.dart';
import 'package:sgela_services/data/assistant_data_openai/thread.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';

class AssistantMain extends StatefulWidget {
  const AssistantMain({super.key, required this.examLink});

  final ExamLink examLink;

  @override
  AssistantMainState createState() => AssistantMainState();
}

class AssistantMainState extends State<AssistantMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Country? country;
  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  static const mm = '🔵🔵🔵🔵 AssistantMain  🔵🔵';

  bool _busy = false;
  OpenAIAssistantService assistantService =
      GetIt.instance<OpenAIAssistantService>();
  File? pdfFile;
  Thread? thread;
  OpenAIAssistant? assistant;

  late StreamSubscription<String> statusSubscription;
  late StreamSubscription<List<Message>> messageSubscription;

  List<Message> messages = [];

  var currentIndexPage = 0;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _getData();
    _startAssistant();
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
        pp('\n\n\n$mm ... $yy$yy$yy Thread run completed!! $yy$yy\n\n\n');
      }
      // if (mounted) {
      //   showToast(
      //       backgroundColor: Colors.blue,
      //       duration: const Duration(seconds: 5),
      //       toastGravity: ToastGravity.TOP,
      //       message: 'SgelaAI status: $status',
      //       context: context);
      // }
    });
    messageSubscription =
        assistantService.questionResponseStream.listen((mMessages) {
      pp('\n\n\n$mm ... Assistant message(s) arrived: ${mMessages.length}');
      _handleMessageArrived(mMessages);
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    });
  }

  static const yy = '💛💛💛', ee = '👿👿👿👿';

  Future<void> _handleMessageArrived(List<Message> mMessages) async {
    pp('\n\n\n$mm ... $yy _handleMessageArrived: Assistant message arrived: $yy');
    String? mText = mMessages.elementAt(0).content?.first.text!.value;

    if (messages.length > 1) {
      pp('$mm ... $yy Handle normal text response ... $yy');
      messages.addAll(mMessages);
    } else {
      pp('$mm ... $yy Extract question list from text .....');
      questions.clear();
      _extractQuestionsFromText(mText!);
      // _pageController.jumpToPage(1);
      if (questions.isEmpty) {
        pp('$mm  $yy Message is not valid JSON object; TRY AGAIN?');
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool isValidJsonObject(String jsonString) {
    try {
      jsonDecode(jsonString);
      pp('$mm Message is  🍎🍎🍎 a valid JSON object');
      return true;
    } catch (e) {
      pp('$mm Message is  $yy NOT a valid JSON object');
      return false;
    }
  }

  List<AssistantQuestion> questions = [];

  _extractQuestionsFromText(String text) {
    try {
      int firstIndex = text.indexOf('[');
      int lastIndex = text.lastIndexOf(']');
      pp('$mm text: ${text.length} firstIndex: $firstIndex lastIndex: $lastIndex');

      String s = text.substring(firstIndex, lastIndex + 1);
      questions.clear();
      List mList = jsonDecode(s);
      for (var value in mList) {
        var aq = AssistantQuestion.fromJson(value);
        aq.date = DateTime.now().toUtc().toIso8601String();
        aq.examLinkId = widget.examLink.id;
        aq.assistantName = assistant?.name;
        aq.assistantId = assistant!.id;
        aq.examLinkTitle = '${widget.examLink.documentTitle} - ${widget.examLink.title}';
        aq.subject = widget.examLink.subject?.title;
        aq.subjectId = widget.examLink.subject?.id;
        questions.add(aq);
      }
      pp('\n\n$mm .................. QUESTIONS found: ${questions.length}');
      FirestoreService service = GetIt.instance<FirestoreService>();
      service.addQuestions(questions);

    } catch (e, s) {
      pp('$mm $yy $e $s');
    }
  }

  late Run run;

  void _startAssistant() async {
    setState(() {
      _busy = true;
    });
    FirestoreService firestoreService = GetIt.instance<FirestoreService>();
    try {
      questions =
          await firestoreService.getAssistantQuestions(widget.examLink.id!);
      assistant = await assistantService.findAssistant(widget.examLink);

      if (questions.isNotEmpty) {
        pp('$mm we have questions .... ${questions.length}');
      } else {
        assistant ??=
            await assistantService.createAssistant(examLink: widget.examLink);
        var msg = await assistantService.createMessage(
            threadId: thread!.id!, text: getQuestionsInstructions);
        pp('$mm ... getQuestionsInstructions message sent: 🍎${msg.id}'
            ' ... start running thread: ${thread!.id!} 🍎');
      }

      pp('$mm ... creating thread ....');
      thread = await assistantService.createThread();
      setState(() {});
      _runThread(true);
    } catch (e, s) {
      pp('$mm $e $s');
      if ((mounted)) {
        fun.showErrorDialog(context, '$e');
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _runThread(bool isQuestion) async {
    pp('$mm ... running thread .... : 🍎${thread!.id!}');
    run = await assistantService.runThread(
        threadId: thread!.id!, assistantId: assistant!.id!);
    pp('$mm ... startPollingTimer .... run: ${run.id}');
    assistantService.startPollingTimer(thread!.id!, run.id!, isQuestion);
  }

  Future _sendPlanMessage() async {
    if (thread == null) {
      return;
    }
    pp('$mm ... _sendPlanMessage .... thread: ${thread!.id!} ');
    setState(() {
      _busy = true;
    });
    try {
      var msg = await assistantService.createMessage(
          text: studyPlanInstructions, threadId: thread!.id!);
      pp('\n\n$mm ... createMessage .... '
          'response from Assistant, check to see if we need to add this to messages: 🍎 ${msg.toJson()} 🍎\n\n');
      messages.add(msg);
      _runThread(false);
    } catch (e, s) {
      pp('$mm $e $s');
      if (mounted) {
        fun.showErrorDialog(context, '$e');
      }
    }
  }

  _getData() async {
    pp('$mm ............................'
        ' getting data ...');
    setState(() {
      _busy = false;
    });
    try {
      organization = prefs.getOrganization();
      country = prefs.getCountry();
    } catch (e) {
      pp(e);
      fun.showErrorDialog(context, '$e');
    }
    setState(() {
      _busy = false;
    });
  }

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      OpenAPIAssistantChat(
        threadId: thread?.id,
        assistantId: assistant?.id,
      ),
      OpenAiAssistantQuestions(
        questions: questions,
        threadId: thread?.id,
        assistantId: assistant?.id,
      ),
      const OpenAiAssistantDocument(),
    ];
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('OpenAI Assistant'),
            ),
            body: ScreenTypeLayout.builder(
              mobile: (_) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                              itemCount: widgets.length,
                              onPageChanged: (pg) {
                                setState(() {
                                  currentIndexPage = pg;
                                });
                              },
                              controller: _pageController,
                              itemBuilder: (_, index) {
                                return widgets.elementAt(index);
                              }),
                        ),
                        // DotsIndicator(
                        //   dotsCount: 3,
                        //   position: currentIndexPage,
                        //   decorator: DotsDecorator(
                        //     colors: [
                        //       Colors.grey[300]!,
                        //       Colors.grey[600]!,
                        //       Colors.grey[900]!
                        //     ], // Inactive dot colors
                        //     activeColors: [
                        //       Colors.red[300]!,
                        //       Colors.red[600]!,
                        //       Colors.red[900]!
                        //     ], // Àctive dot colors
                        //   ),
                        // ),
                        const SponsoredBy(
                          height: 32,
                        ),
                      ],
                    ),
                    _busy
                        ? const Positioned(
                            bottom: 48,
                            left: 8,
                            right: 8,
                            child: SizedBox(
                              height: 180,
                              width: 400,
                              child: BusyIndicator(
                                caption:
                                    'Working on the questions with SgelaAI ...',
                                showClock: false,
                              ),
                            ))
                        : gapW16,
                  ],
                );
              },
              tablet: (_) {
                return const Stack();
              },
              desktop: (_) {
                return const Stack();
              },
            )));
  }
}
