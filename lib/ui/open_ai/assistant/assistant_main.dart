import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edu_chatbot/local_util/functions.dart' as fun;
import 'package:edu_chatbot/local_util/functions.dart';
import 'package:edu_chatbot/ui/exam/pdf_viewer.dart';
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
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
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
  Sponsoree? sponsoree;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _getData();
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
        pp('\n\n\n$mm ... $yy$yy$yy Thread run completed!! $yy$yy$yy\n\n\n');
      }
    });
    messageSubscription =
        assistantService.questionResponseStream.listen((mMessages) {
      pp('\n\n\n$mm ... Assistant message(s) arrived, messages length: ${mMessages.length}\n');
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
    String? mText = mMessages.elementAt(0).content?.first.text!.value;
    pp('$mm ... $yy _handleMessageArrived: Assistant message arrived: $yy $mText');

    if (questions.isEmpty) {
      //messages must be a list of questions
      _extractQuestionsFromText(mText!);
      if (questions.isNotEmpty) {
        pp('$mm  $yy Questions are cool ..... we have: ${questions.length}');
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 500), // Animation duration
          curve: Curves.ease, // Animation curve
        ); //
      }
      return;
    }
    messages = mMessages;
    if (mounted) {
      setState(() {});
    }
    if (thread != null) {
      assistantService.getTokens(
          model: assistant!.model!,
          sponsoree: sponsoree!,
          threadId: thread!.id!);
    }
  }

  List<AssistantQuestion> questions = [];

  _extractQuestionsFromText(String text) {
    try {
      questions.clear();
      int firstIndex = text.indexOf('[');
      int lastIndex = text.lastIndexOf(']');
      pp('$mm text: ${text.length} firstIndex: $firstIndex lastIndex: $lastIndex');

      if (firstIndex == -1 || lastIndex == -1) {
        return;
      }
      String s = text.substring(firstIndex, lastIndex + 1);
      pp('\n\n\\n$mm List of Extracted Questions');

      List mList = jsonDecode(s);
      for (var value in mList) {
        var aq = AssistantQuestion.fromJson(value);
        aq.date = DateTime.now().toUtc().toIso8601String();
        aq.examLinkId = widget.examLink.id;
        aq.assistantName = assistant?.name;
        aq.assistantId = assistant!.id;
        aq.examLinkTitle =
            '${widget.examLink.documentTitle} - ${widget.examLink.title}';
        aq.subject = widget.examLink.subject?.title;
        aq.subjectId = widget.examLink.subject?.id;
        questions.add(aq);
        pp('$mm Question: ${aq.toJson()}');
      }

      if (questions.isEmpty) {
        return;
      }
      pp('\n\n$mm .................. QUESTIONS found: ${questions.length}, will be added to Firestore');
      FirestoreService service = GetIt.instance<FirestoreService>();
      service.addQuestions(questions);
    } catch (e, s) {
      pp('$mm $yy $e $s');
    }
  }

  late Run run;
  int maxRetries = 3;
  int retryCount = 0;

  void _startAssistant() async {
    pp('\n\n\n$mm ... _startAssistant: get or create Assistant, '
        '... start running thread \n\n');
    retryCount++;
    if (retryCount > maxRetries) {
      fun.showToast(
          message:
              'SgelaAI unable to help you at this time. Please try again later',
          context: context);
      return;
    }

    FirestoreService firestoreService = GetIt.instance<FirestoreService>();
    try {
      questions =
          await firestoreService.getAssistantQuestions(widget.examLink.id!);
      assistant = await assistantService.findAssistant(widget.examLink);
      assistant ??=
          await assistantService.createAssistant(examLink: widget.examLink);

      if (questions.isEmpty) {
        pp('$mm ... creating thread ....');
        var msg = {
          'role': 'user',
          'content':
              'Please build the list of questions as per the assistant instructions',
          'metadata': {},
          'file_ids': [],
        };
        thread = await assistantService.createThreadWithMessages([msg]);
      } else {
        thread = await assistantService.createThread();
      }
      //
      if (questions.isNotEmpty) {
        pp('$mm we have questions .... ${questions.length}');
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 500), // Animation duration
          curve: Curves.ease, // Animation curve
        ); //
      } else {
        var msg = await assistantService.createMessage(
            threadId: thread!.id!, text: getQuestionsInstructions);
        pp('\n\n$mm ... getQuestionsInstructions message sent: 🍎${msg.id}'
            ' ... start running thread: ${thread!.id!} 🍎 ');
        _runThread(true);
      }
    } catch (e, s) {
      pp('$mm $e $s');
      if ((mounted)) {
        fun.showErrorDialog(context, '$e');
        Navigator.of(context).pop();
      }
    }
    setState(() {});
  }

  Future<void> _runThread(bool isQuestion) async {
    pp('$mm ... start running thread .... : 🍎${thread!.id!}');
    run = await assistantService.runThread(
        threadId: thread!.id!, assistantId: assistant!.id!);
    pp('$mm ... startPollingTimer .... run: ${run.id}');
    //
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
      _busy = true;
    });
    FirestoreService firestoreService = GetIt.instance<FirestoreService>();
    try {
      organization = prefs.getOrganization();
      country = prefs.getCountry();
      sponsoree = prefs.getSponsoree();
      questions =
          await firestoreService.getAssistantQuestions(widget.examLink.id!);
      pp('$mm questions from Firestore: ${questions.length}');
    } catch (e) {
      pp(e);
      if (mounted) {
        fun.showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
    _startAssistant();
    if (questions.isNotEmpty) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 500), // Animation duration
        curve: Curves.ease, // Animation curve
      ); //
    }
  }

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      OpenAPIAssistantChat(
        threadId: thread?.id,
        assistant: assistant,
        messages: messages,
        examLink: widget.examLink,
      ),
      OpenAiAssistantQuestions(
        questions: questions,
        threadId: thread?.id,
        assistantId: assistant?.id,
        examLink: widget.examLink,
        onMessagesReceived: (mMessages) {
          messages = mMessages;
          setState(() {});
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500), // Animation duration
            curve: Curves.ease, // Animation curve
          ); //
        },
      ),
      const OpenAiAssistantDocument(),
    ];
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('OpenAI Assistant'),
              actions: [
                IconButton(
                  onPressed: () {
                    NavigationUtils.navigateToPage(
                        context: context,
                        widget: PDFViewer(
                            pdfUrl: widget.examLink.link!,
                            examLink: widget.examLink));
                  },
                  icon: const Icon(Icons.cloud_download),
                ),
              ],
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
                              physics: const PageScrollPhysics(),
                              controller: _pageController,
                              itemBuilder: (_, index) {
                                return widgets.elementAt(index);
                              }),
                        ),
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
