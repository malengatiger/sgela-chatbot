import 'package:edu_chatbot/data/exam_document.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/services/you_tube_service.dart';
import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:edu_chatbot/ui/exam_link_list_widget.dart';
import 'package:edu_chatbot/ui/you_tube_searcher.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:flutter/material.dart';

import '../data/subject.dart';
import '../services/chat_service.dart';
import '../util/dark_light_control.dart';
import '../util/functions.dart';
import '../util/prefs.dart';
import 'color_gallery.dart';

class ExamsDocumentList extends StatefulWidget {
  const ExamsDocumentList(
      {super.key,
      required this.repository,
      required this.subject,
      required this.localDataService,
      required this.chatService,
      required this.youTubeService,
      required this.downloaderService,
      required this.prefs,
      required this.colorWatcher});

  final Repository repository;
  final Subject subject;
  final LocalDataService localDataService;
  final ChatService chatService;
  final YouTubeService youTubeService;
  final DownloaderService downloaderService;
  final Prefs prefs;
  final ColorWatcher colorWatcher;

  @override
  ExamsDocumentListState createState() => ExamsDocumentListState();
}

class ExamsDocumentListState extends State<ExamsDocumentList> {
  static const mm = '🔵🔵🔵🔵ExamsByDocument';

  @override
  void initState() {
    super.initState();
    _fetchExamDocuments();
  }

  bool busy = false;
  List<ExamDocument> examDocs = [];

  _fetchExamDocuments() async {
    try {
      setState(() {
        busy = true;
      });
      examDocs = await widget.repository.getExamDocuments(false);
      examDocs.sort((b, a) => a.title!.compareTo(b.title!));
    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      busy = false;
    });
  }

  _navigateToExamLinks(ExamDocument examDocument) {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ExamLinkListWidget(
          subject: widget.subject,
          repository: widget.repository,
          localDataService: widget.localDataService,
          chatService: widget.chatService,
          youTubeService: widget.youTubeService,
          downloaderService: widget.downloaderService,
          examDocument: examDocument,
          prefs: widget.prefs,
          colorWatcher: widget.colorWatcher,
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

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ColorGallery(
            prefs: widget.prefs, colorWatcher: widget.colorWatcher));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title:
                  Text('Examination Periods', style: myTextStyleSmall(context)),
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
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('${widget.subject.title}',
                          style: myTextStyle(
                              context,
                              Theme.of(context).primaryColor,
                              18,
                              FontWeight.w900)),
                      Expanded(
                        child: busy
                            ? const BusyIndicator(
                                caption: "Loading exam documents. Gimme a second ...",
                              )
                            : ListView.builder(
                                itemCount: examDocs.length,
                                itemBuilder: (_, index) {
                                  var doc = examDocs.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      _navigateToExamLinks(doc);
                                    },
                                    child: Card(
                                      elevation: 8,
                                      child: ListTile(
                                        title: Text(
                                          '${doc.title}',
                                          style: myTextStyleSmall(context),
                                        ),
                                        leading: Icon(Icons.edit_note,
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                    ),
                                  );
                                }),
                      )
                    ],
                  ),
                )
              ],
            )));
  }
}
