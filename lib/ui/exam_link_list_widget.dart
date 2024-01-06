import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/chat_service.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/services/you_tube_service.dart';
import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:edu_chatbot/ui/exam_paper_pages.dart';
import 'package:edu_chatbot/ui/text_chat.dart';
import 'package:edu_chatbot/ui/you_tube_searcher.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

import '../data/exam_document.dart';
import '../services/local_data_service.dart';
import '../util/functions.dart';
import '../util/navigation_util.dart';

class ExamLinkListWidget extends StatefulWidget {
  final Subject subject;
  final Repository repository;
  final LocalDataService localDataService;
  final ChatService chatService;
  final YouTubeService youTubeService;
  final DownloaderService downloaderService;
  final ExamDocument examDocument;

  const ExamLinkListWidget({
    super.key,
    required this.subject,
    required this.repository,
    required this.localDataService,
    required this.chatService,
    required this.youTubeService,
    required this.downloaderService,
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

  List<FocusedMenuItem> _getMenuItems(ExamLink examLink, BuildContext context) {
    List<FocusedMenuItem> list = [];

    list.add(FocusedMenuItem(
        title:
            Text('Use Image and Text', style: myTextStyleSmallBlack(context)),
        // backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.camera_alt,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          _navigateToExamPaperPages(examLink);
        }));
    list.add(FocusedMenuItem(
        title: Text('Use Text Search', style: myTextStyleSmallBlack(context)),
        // backgroundColor: Theme.of(context).primaryColor,
        trailingIcon: Icon(
          Icons.search,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          _navigateToChat(examLink);
        }));

    return list;
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
              icon: const Icon(Icons.video_collection))
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
                          caption: 'Loading subject exams',
                          showClock: true,
                        )
                      : ListView.builder(
                          itemCount: filteredExamLinks.length,
                          itemBuilder: (context, index) {
                            ExamLink examLink = filteredExamLinks[index];
                            return FocusedMenuHolder(
                              menuItems: _getMenuItems(examLink, context),
                              menuOffset: 20,
                              duration: const Duration(milliseconds: 300),
                              animateMenuItems: true,
                              openWithTap: true,
                              onPressed: () {
                                pp('💛️💛️💛💛️💛️💛💛️💛️💛️ tapped FocusedMenuHolder ...');
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

  void _navigateToChat(ExamLink examLink) {
    pp('$mm _navigateToChat ...');
    NavigationUtils.navigateToPage(
        context: context,
        widget: TextChat(
          examLink: examLink,
          chatService: widget.chatService,
          repository: widget.repository,
          subject: widget.subject,
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
          showSearchBox: true,
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
          fontWeight: FontWeight.w900,
        );
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
