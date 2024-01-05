import 'package:edu_chatbot/data/exam_document.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/services/you_tube_service.dart';
import 'package:edu_chatbot/ui/exam_link_list_widget.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:flutter/material.dart';

import '../data/subject.dart';
import '../services/chat_service.dart';
import '../util/functions.dart';

class ExamsDocumentList extends StatefulWidget {
  const ExamsDocumentList(
      {super.key,
      required this.repository,
      required this.subject,
      required this.localDataService,
      required this.chatService,
      required this.youTubeService,
      required this.downloaderService});

  final Repository repository;
  final Subject subject;
  final LocalDataService localDataService;
  final ChatService chatService;
  final YouTubeService youTubeService;
  final DownloaderService downloaderService;

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
      examDocs.sort((a, b) => a.title!.compareTo(b.title!));
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
        ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Examination Periods'),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    const Text('Available Examination Papers'),
                    Expanded(
                      child: ListView.builder(
                          itemCount: examDocs.length,
                          itemBuilder: (_, index) {
                            var doc = examDocs.elementAt(index);
                            return GestureDetector(
                              onTap: (){
                                _navigateToExamLinks(doc);
                              },
                              child: Card(
                                elevation: 8,
                                child: Text('${doc.title}'),
                              ),
                            );
                          }),
                    )
                  ],
                )
              ],
            )));
  }
}
