import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/ui/gemini/sections/exam_page_content_selector.dart';
import 'package:edu_chatbot/ui/gemini/sections/gemini_multi_turn_chat_stream.dart';
import 'package:edu_chatbot/ui/groq/groq_chat_stream.dart';
import 'package:edu_chatbot/ui/open_ai/open_ai_text_chat_widget.dart';
import 'package:edu_chatbot/ui/youtube/you_tube_searcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/assistant_data_openai/assistant.dart';
import 'package:sgela_services/data/exam_document.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:sgela_services/repositories/basic_repository.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/gemini_chat_service.dart';
import 'package:sgela_services/services/local_data_service.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/services/you_tube_service.dart';
import 'package:sgela_services/sgela_util/dark_light_control.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/color_gallery.dart';
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';

import '../../local_util/functions.dart';
import '../chat/model_chooser.dart' as chooser;

class ExamLinkListWidget extends StatefulWidget {
  final Subject subject;
  final ExamDocument examDocument;

  const ExamLinkListWidget({
    super.key,
    required this.subject,
    required this.examDocument,
  });

  @override
  ExamLinkListWidgetState createState() => ExamLinkListWidgetState();
}

class ExamLinkListWidgetState extends State<ExamLinkListWidget> {
  List<ExamLink> examLinks = [];
  List<ExamLink> filteredExamLinks = [];
  static const mm = '🍎🍎🍎ExamLinkListWidget 🍎';
  bool busy = false;
  final BasicRepository repository = GetIt.instance<BasicRepository>();
  final LocalDataService localDataService = GetIt.instance<LocalDataService>();
  final GeminiChatService chatService = GetIt.instance<GeminiChatService>();
  final YouTubeService youTubeService = GetIt.instance<YouTubeService>();

  // final DownloaderService downloaderService;
  final Prefs prefs = GetIt.instance<Prefs>();
  final ColorWatcher colorWatcher = GetIt.instance<ColorWatcher>();
  final Gemini gemini = GetIt.instance<Gemini>();
  final FirestoreService firestoreService = GetIt.instance<FirestoreService>();

  @override
  void initState() {
    super.initState();
    _getExamLinks();
  }

  Future<void> _getExamLinks() async {
    pp('$mm  ............... _getExamLinks ...');
    try {
      setState(() {
        busy = true;
      });
      examLinks = await firestoreService.getExamLinksByDocumentAndSubject(
          subjectId: widget.subject.id!, documentId: widget.examDocument.id!);
      pp('$mm fetchedExamLinks: examLinks: ${examLinks.length}');
      aiModel = prefs.getCurrentModel();
      filteredExamLinks = examLinks;
      filteredExamLinks.sort((a, b) => a.title!.compareTo(b.title!));
    } catch (e) {
      // Handle error
      pp('$mm 👿👿👿👿👿Error fetching exam links: $e');
      if (mounted) {
        showErrorDialog(context, 'Failed to get exam data');
      }
    }
    setState(() {
      busy = false;
    });
  }

  ExamLink? selectedExamLink;
  OpenAIAssistantService assistantService =
      GetIt.instance<OpenAIAssistantService>();
  OpenAIAssistant? assistant;

  String? aiModel;

  void _navigateToPageContentSelector(ExamLink examLink) {
    NavigationUtils.navigateToPage(
        context: context, widget: ExamPageContentSelector(examLink: examLink));

    // NavigationUtils.navigateToPage(
    //     context: context,
    //     widget: AssistantMain(examLink: examLink));
  }

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context, widget: ColorGallery(colorWatcher: colorWatcher));
  }

  void _navigateToChat() {
    switch (aiModel) {
      case modelGeminiAI:
        NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiMultiTurnStreamChat(
              subject: widget.subject,
            ));
        break;
      case modelOpenAI:
        NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAITextChatWidget(
              subject: widget.subject,
            ));
        break;
      case modelMixtral:
        NavigationUtils.navigateToPage(
            context: context,
            widget: GroqChat(
              subject: widget.subject,
            ));
        break;
      default:
        if (mounted) {
          showToast(message: 'Defaulting to OpenAI model', context: context);
        }
        NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAITextChatWidget(
              subject: widget.subject,
            ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
            );
    double height = 0.0;
    switch (filteredExamLinks.length) {
      case 1:
        height = 120;
        break;
      case 2:
        height = 120 * 2;
        break;
      case 3:
        height = 120 * 3;
        break;
      case 4:
        height = 120 * 4;
        break;
      case 5:
        height = 120 * 5;
        break;
      case 6:
        height = 120 * 6;
        break;
      default:
        height = 400;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [],
        ),
        actions: [
          IconButton(
              onPressed: () {
                _navigateToYouTube();
              },
              icon: Icon(Icons.video_collection,
                  color: Theme.of(context).primaryColor)),
          IconButton(
              onPressed: () {
                _navigateToColorGallery();
              },
              icon: Icon(Icons.color_lens_outlined,
                  color: Theme.of(context).primaryColor)),
          IconButton(
              onPressed: () {
                _navigateToChat();
              },
              icon: Icon(Icons.chat, color: Theme.of(context).primaryColor)),
          chooser.ModelChooser(
            onSelected: (model) {
              setState(() {
                aiModel = model;
              });
            },
          ),
        ],
      ),
      // backgroundColor: Colors.teal,
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    gapH32,
                    gapH32,
                    Text(
                      'Exam Papers',
                      style: myTextStyle(context,
                          Theme.of(context).primaryColor, 32, FontWeight.w900),
                    ),
                    filteredExamLinks.length < 4 ? gapH32 : gapH16,
                    Text(
                      '${widget.subject.title}',
                      style: titleStyle,
                    ),
                    gapH4,
                    Text(
                      '${widget.examDocument.title}',
                      style: myTextStyleSmall(context),
                    ),
                    filteredExamLinks.length < 4 ? gapH32 : gapH16,
                    SizedBox(
                      height: height,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8),
                        child: Card(
                          elevation: 8,
                          child: bd.Badge(
                            position:
                                bd.BadgePosition.topEnd(top: -16, end: -2),
                            badgeContent: Text(
                              '${filteredExamLinks.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            badgeStyle: bd.BadgeStyle(
                                padding: const EdgeInsets.all(12.0),
                                badgeColor: Colors.red.shade800,
                                elevation: 12),
                            child: busy
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: BusyIndicator(
                                      caption:
                                          'Loading subject exams ... gimme a second ...',
                                      showClock: true,
                                    ),
                                  )
                                : Align(
                                    alignment: Alignment.center,
                                    child: ListView.builder(
                                      itemCount: filteredExamLinks.length,
                                      itemBuilder: (context, index) {
                                        ExamLink examLink =
                                            filteredExamLinks[index];
                                        return GestureDetector(
                                          onTap: () {
                                            selectedExamLink = examLink;
                                            _navigateToPageContentSelector(
                                                examLink);
                                          },
                                          child: ExamLinkWidget(
                                            examLink: examLink,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    gapH32,
                    filteredExamLinks.length < 4 ? gapH32 : gapH4,
                    gapH32,
                    const SponsoredBy(height: 32),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  void _navigateToGeminiMultiTurnStreamChat() {
    pp('$mm _navigateToGeminiMultiTurnStreamChat ...');

    NavigationUtils.navigateToPage(
        context: context,
        widget: GeminiMultiTurnStreamChat(
          subject: widget.subject,
        ));
  }

  void _navigateToOpenAIMultiTurnStreamChat() {
    pp('$mm _navigateToOpenAIMultiTurnStreamChat ...');

    NavigationUtils.navigateToPage(
        context: context,
        widget: OpenAITextChatWidget(subject: widget.subject));
  }

  void _navigateToExamPageContentSelector(ExamLink examLink) {
    pp('$mm .............. _navigateToExamPageContentSelector ...');

    aiModelName ??= 'OpenAI';
    NavigationUtils.navigateToPage(
        context: context,
        widget: ExamPageContentSelector(
          examLink: examLink,
        ));
  }

  String? aiModelName = modelGeminiAI;

  void _navigateToYouTube() {
    pp('$mm _navigateToYouTube ... widget.subject.id: ${widget.subject.id}');
    NavigationUtils.navigateToPage(
        context: context,
        widget: YouTubeSearcher(
          subject: widget.subject,
        ));
  }
}

class ExamLinkWidget extends StatelessWidget {
  final ExamLink examLink;
  static const mm = '🍎🍎🍎ExamLinkWidget 🍎';

  const ExamLinkWidget({
    super.key,
    required this.examLink,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
            );
    final TextStyle idStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ListTile(
            title: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    '${examLink.id}',
                    style: idStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    examLink.title ?? '',
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${examLink.documentTitle}',
              style: myTextStyleSmall(context),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatTypeChooser extends StatelessWidget {
  const ChatTypeChooser({super.key, required this.onChatTypeChosen});

  final Function(int) onChatTypeChosen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: ElevatedButton(
              style: const ButtonStyle(
                elevation: MaterialStatePropertyAll(8),
              ),
              onPressed: () {
                onChatTypeChosen(CHAT_TYPE_IMAGE);
              },
              child: Text(
                'Search using exam paper',
                style: myTextStyle(context, Theme.of(context).primaryColor, 16,
                    FontWeight.normal),
              ),
            ),
          ),
          gapH8,
          SizedBox(
            width: 300,
            child: ElevatedButton(
              style: const ButtonStyle(
                elevation: MaterialStatePropertyAll(8),
              ),
              onPressed: () {
                onChatTypeChosen(CHAT_TYPE_MULTI_TURN);
              },
              child: Text(
                'Search with text',
                style: myTextStyle(context, Theme.of(context).primaryColor, 16,
                    FontWeight.normal),
              ),
            ),
          ),
          gapH8,
          SizedBox(
            width: 300,
            child: ElevatedButton(
              style: const ButtonStyle(
                elevation: MaterialStatePropertyAll(8),
              ),
              onPressed: () {
                onChatTypeChosen(CHAT_TYPE_MULTI_TURN);
              },
              child: Text(
                'Find Answers',
                style: myTextStyle(context, Theme.of(context).primaryColor, 16,
                    FontWeight.normal),
              ),
            ),
          )
        ],
      ),
    );
  }
}

const CHAT_TYPE_IMAGE = 1, CHAT_TYPE_MULTI_TURN = 2;
