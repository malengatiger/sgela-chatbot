import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/gemini/sections/multi_turn_chat_stream.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/chat_service.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/services/you_tube_service.dart';
import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:edu_chatbot/ui/exam_paper_pages.dart';
import 'package:edu_chatbot/ui/you_tube_searcher.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import '../data/exam_document.dart';
import '../services/local_data_service.dart';
import '../util/functions.dart';
import '../util/navigation_util.dart';
import '../util/prefs.dart';
import 'color_gallery.dart';

class ExamLinkListWidget extends StatefulWidget {
  final Subject subject;
  final Repository repository;
  final LocalDataService localDataService;
  final ChatService chatService;
  final YouTubeService youTubeService;
  final DownloaderService downloaderService;
  final ExamDocument examDocument;
  final Prefs prefs;
  final ColorWatcher colorWatcher;
  final Gemini gemini;

  const ExamLinkListWidget({
    super.key,
    required this.subject,
    required this.repository,
    required this.localDataService,
    required this.chatService,
    required this.youTubeService,
    required this.downloaderService,
    required this.examDocument,
    required this.prefs,
    required this.colorWatcher,
    required this.gemini,
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
      List<ExamLink> fetchedExamLinks = await widget.repository
          .getExamLinksByDocument(
              widget.subject, widget.examDocument.title!, false);
      pp('$mm fetchedExamLinks: ${fetchedExamLinks.length}');

      examLinks = fetchedExamLinks;
      filteredExamLinks = fetchedExamLinks;
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
              examLink.title!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  ExamLink? selectedExamLink;

  _showChooserDialog() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return AlertDialog(
            title: Column(
              children: [
                Text(
                  selectedExamLink!.title!,
                  style: myTextStyleSmall(context),
                ),
                gapH16,
                Text(
                  'What do you want to do?',
                  style: myTextStyleMedium(context),
                ),
              ],
            ),
            elevation: 12,
            content: ChatTypeChooser(onChatTypeChosen: (type) {
              //Navigator.of(context).pop();
              if ((type == CHAT_TYPE_MULTI_TURN)) {
                _navigateToMultiTurnStreamChat(selectedExamLink!);
              }
              if ((type == CHAT_TYPE_IMAGE)) {
                _navigateToExamPaperPages(selectedExamLink!);
              }
            }),
          );
        });
  }

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ColorGallery(
            prefs: widget.prefs, colorWatcher: widget.colorWatcher));
  }

  @override
  Widget build(BuildContext context) {
    pp('$mm .... build ...');
    final TextStyle titleStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
            );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject.title}',
          style: titleStyle,
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8,
                  top: 4,
                  bottom: 8,
                ),
                child: TextField(
                  onChanged: _filterExamLinks,
                  decoration: const InputDecoration(
                    labelText: 'Search Exams',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: bd.Badge(
                  position: bd.BadgePosition.topEnd(top: -8, end: -2),
                  badgeContent: Text(
                    '${filteredExamLinks.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  badgeStyle: bd.BadgeStyle(
                      padding: const EdgeInsets.all(8.0),
                      badgeColor: Colors.red.shade800,
                      elevation: 12),
                  child: busy
                      ? const BusyIndicator(
                          caption:
                              'Loading subject exams ... gimme a second ...',
                          showClock: true,
                        )
                      : ListView.builder(
                          itemCount: filteredExamLinks.length,
                          itemBuilder: (context, index) {
                            ExamLink examLink = filteredExamLinks[index];
                            return GestureDetector(
                              onTap: () {
                                selectedExamLink = examLink;
                                _showChooserDialog();
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
          ],
        ),
      ),
    );
  }

  void _navigateToMultiTurnStreamChat(ExamLink examLink) {
    pp('$mm _navigateToMultiTurnStreamChat ...');
    NavigationUtils.navigateToPage(
        context: context,
        widget: MultiTurnStreamChat(
          gemini: widget.gemini,
          examLink: selectedExamLink!,
        ));
  }

  void _navigateToExamPaperPages(ExamLink examLink) {
    pp('$mm _navigateToExamPaperPages ...');
    examLink.subjectTitle = widget.subject.title;
    examLink.subjectId = widget.subject.id;
    NavigationUtils.navigateToPage(
        context: context,
        widget: ExamPaperPages(
          examLink: examLink,
          repository: widget.repository,
          chatService: widget.chatService,
          downloaderService: widget.downloaderService,
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
    final TextStyle idStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor);
    return Card(
      elevation: 2,
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
    );
  }
}

class ChatTypeChooser extends StatelessWidget {
  const ChatTypeChooser({super.key, required this.onChatTypeChosen});

  final Function(int) onChatTypeChosen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              onChatTypeChosen(CHAT_TYPE_IMAGE);
            },
            child: Row(
              children: [
                // IconButton(
                //   onPressed: () {
                //     onChatTypeChosen(CHAT_TYPE_IMAGE);
                //   },
                //   icon: Icon(
                //     Icons.image_search,
                //     size: 16,
                //     color: Theme.of(context).primaryColor,
                //   ),
                // ),
                // gapW8,
                TextButton(
                  onPressed: () {
                    onChatTypeChosen(CHAT_TYPE_IMAGE);
                  },
                  child: Flexible(
                    child: Text(
                      'Search using exam paper',
                      style: myTextStyle(
                          context,
                          Theme.of(context).primaryColor,
                          16,
                          FontWeight.normal),
                    ),
                  ),
                )
              ],
            ),
          ),
          gapH8,
          GestureDetector(
            onTap: () {
              onChatTypeChosen(CHAT_TYPE_MULTI_TURN);
            },
            child: Row(
              children: [

                TextButton(
                  onPressed: () {
                    onChatTypeChosen(CHAT_TYPE_MULTI_TURN);
                  },
                  child: Flexible(
                    child: Text(
                      'Search with text',
                      style: myTextStyle(
                          context,
                          Theme.of(context).primaryColor,
                          16,
                          FontWeight.normal),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

const CHAT_TYPE_IMAGE = 1, CHAT_TYPE_MULTI_TURN = 2;
