import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/gemini/sections/exam_page_content_list.dart';
import 'package:edu_chatbot/gemini/sections/multi_turn_chat_stream.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/chat_service.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/you_tube_service.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/powered_by.dart';
import 'package:edu_chatbot/ui/youtube/you_tube_searcher.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import '../../data/exam_document.dart';
import '../../services/local_data_service.dart';
import '../../util/functions.dart';
import '../../util/navigation_util.dart';
import '../../util/prefs.dart';
import '../misc/color_gallery.dart';

class ExamLinkListWidget extends StatefulWidget {
  final Subject subject;
  final Repository repository;
  final LocalDataService localDataService;
  final ChatService chatService;
  final YouTubeService youTubeService;

  // final DownloaderService downloaderService;
  final ExamDocument examDocument;
  final Prefs prefs;
  final ColorWatcher colorWatcher;
  final Gemini gemini;
  final FirestoreService firestoreService;

  const ExamLinkListWidget({
    super.key,
    required this.subject,
    required this.repository,
    required this.localDataService,
    required this.chatService,
    required this.youTubeService,
    // required this.downloaderService,
    required this.examDocument,
    required this.prefs,
    required this.colorWatcher,
    required this.gemini,
    required this.firestoreService,
  });

  @override
  ExamLinkListWidgetState createState() => ExamLinkListWidgetState();
}

class ExamLinkListWidgetState extends State<ExamLinkListWidget> {
  List<ExamLink> examLinks = [];
  List<ExamLink> filteredExamLinks = [];
  static const mm = '🍎🍎🍎ExamLinkListWidget 🍎';
  bool busy = false;

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
      examLinks = await widget.firestoreService
          .getExamLinksByDocumentAndSubject(
              subjectId: widget.subject.id!,
              documentId: widget.examDocument.id!);
      pp('$mm fetchedExamLinks: examLinks: ${examLinks.length}');
      filteredExamLinks = examLinks;
      filteredExamLinks.sort((a,b) => a.title!.compareTo(b.title!));

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

  void _filterExamLinks(String query) {
    setState(() {
      filteredExamLinks = examLinks
          .where((examLink) =>
              !examLink.title!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  ExamLink? selectedExamLink;

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ColorGallery(
            prefs: widget.prefs, colorWatcher: widget.colorWatcher));
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
            );
   double height = 0.0;
    switch(filteredExamLinks.length) {
      case 1:
        height = 120;
        break;
      case 2:
        height = 120*2;
        break;
      case 3:
        height = 120*3;
        break;
      case 4:
        height = 120*4;
        break;
      case 5:
        height = 120*5;
        break;
      case 6:
        height = 120*6;
        break;
      default:
        height = 400;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              '${widget.subject.title}',
              style: titleStyle,
            ),
            gapH4,
            Text(
              '${widget.examDocument.title}',
              style: myTextStyleSmall(context),
            )
          ],
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
                  color: Theme.of(context).primaryColor))
        ],
      ),
      // backgroundColor: Colors.teal,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // gapH32,
            Text(
              'Exam Papers',
              style: myTextStyle(
                  context, Theme.of(context).primaryColor, 32, FontWeight.w900),
            ),
            gapH32,
            gapH32,
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12),
                child: Card(
                  elevation: 8,
                  child: bd.Badge(
                    position: bd.BadgePosition.topEnd(top: -16, end: -2),
                    badgeContent: Text(
                      '${filteredExamLinks.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    badgeStyle: bd.BadgeStyle(
                        padding: const EdgeInsets.all(8.0),
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
                                ExamLink examLink = filteredExamLinks[index];
                                return GestureDetector(
                                  onTap: () {
                                    selectedExamLink = examLink;
                                    _navigateToExamPageContentSelector(examLink);
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
            const SponsoredBy(),
          ],
        ),
      ),
    );
  }

  void _navigateToMultiTurnStreamChat(ExamLink examLink) {
    pp('$mm _navigateToMultiTurnStreamChat ...');

    NavigationUtils.navigateToPage(
        context: context,
        widget: const MultiTurnStreamChat());
  }

  void _navigateToExamPageContentSelector(ExamLink examLink) {
    pp('$mm .............. _navigateToExamPageContentSelector ...');

    NavigationUtils.navigateToPage(
        context: context,
        widget: ExamPageContentSelector(
          examLink: examLink,
        ));
  }

  void _navigateToYouTube() {
    pp('$mm _navigateToYouTube ... widget.subject.id: ${widget.subject.id}');
    NavigationUtils.navigateToPage(
        context: context,
        widget: YouTubeSearcher(
          youTubeService: widget.youTubeService,
          subject: widget.subject,
          prefs: widget.prefs,
          colorWatcher: widget.colorWatcher,
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
          padding: const EdgeInsets.all(8.0),
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
