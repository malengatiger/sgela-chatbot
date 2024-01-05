import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:edu_chatbot/ui/exams_by_document.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/local_data_service.dart';
import '../services/you_tube_service.dart';
import '../util/navigation_util.dart';
import '../util/prefs.dart';
import 'exam_link_list_widget.dart';
import 'image_picker_widget.dart';

class SubjectSearch extends StatefulWidget {
  final Repository repository;
  final LocalDataService localDataService;
  final ChatService chatService;
  final YouTubeService youTubeService;

  final DownloaderService downloaderService;

  const SubjectSearch(
      {super.key,
      required this.repository,
      required this.localDataService,
      required this.chatService,
      required this.youTubeService, required this.downloaderService});

  @override
  SubjectSearchState createState() => SubjectSearchState();
}

class SubjectSearchState extends State<SubjectSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<Subject> _subjects = [];
  List<Subject> _filteredSubjects = [];
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _getSubjects();
  }

  void _getSubjects() async {
    setState(() {
      busy = true;
    });
    try {
      _subjects = await widget.repository.getSubjects(false);
      _subjects.sort((a, b) => a.title!.compareTo(b.title!));
      _filteredSubjects = _subjects;
    } catch (e) {
      // Handle error
      pp('Error fetching _subjects: $e');
    }
    setState(() {
      busy = false;
    });
  }

  void _filterSubjects(String query) {
    setState(() {
      _filteredSubjects = _subjects
          .where((subject) =>
              subject.title!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  _navigateToAI(BuildContext context) {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ImagePickerWidget(
          chatService: widget.chatService,
        ));
  }

  navigateToExamLinkListWidget(BuildContext context, Subject subject) {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ExamsDocumentList(
          subject: subject,
          downloaderService: widget.downloaderService,
          repository: widget.repository,
          localDataService: widget.localDataService,
          chatService: widget.chatService,
          youTubeService: widget.youTubeService,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int mode = 0;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w900,
            );
    var bright = MediaQuery.of(context).platformBrightness;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title:  Text('SgelaAI', style: myTextStyle(context, Theme.of(context).primaryColor,
                24, FontWeight.w900),),
            actions: [
              IconButton(
                onPressed: () async {
                  await _handleMode(bright);
                },
                icon: Icon(mode == 1 ? Icons.dark_mode : Icons.light_mode),
              ),
              IconButton(
                onPressed: () {
                  _navigateToAI(context);
                },
                icon: const Icon(Icons.camera),
              )
            ],
          ),
          // backgroundColor: bright == Brightness.light?Colors.brown.shade100:Colors.black,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      pp('🍎 🍎 ........ value: $value');
                      _filterSubjects(value);
                    },
                    // autofocus: false,
                    decoration: const InputDecoration(
                        hintText: 'Search Subjects', icon: Icon(Icons.search)),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: bd.Badge(
                    position: bd.BadgePosition.topEnd(top: -8, end: -2),
                    badgeContent: Text(
                      '${_filteredSubjects.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    badgeStyle: bd.BadgeStyle(
                        padding: const EdgeInsets.all(8.0),
                        badgeColor: Colors.pink.shade800,
                        elevation: 12),
                    child: busy? const BusyIndicator(
                      caption: 'Loading subjects'
                    ): ListView.builder(
                      itemCount: _filteredSubjects.length,
                      itemBuilder: (context, index) {
                        Subject subject = _filteredSubjects[index];
                        return GestureDetector(
                          onTap: () {
                            navigateToExamLinkListWidget(context, subject);
                          },
                          child: Card(
                            elevation: 8,
                            shape: getDefaultRoundedBorder(),
                            child: ListTile(
                              leading: const Icon(Icons.ac_unit),
                              title: Text(
                                subject.title ?? '',
                                style: titleStyle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMode(Brightness bright) async {
    mode = await Prefs.getMode();
    if (mode > -1) {
      switch (mode) {
        case 1:
          DarkLightControl.setLightMode();
          break;
        case 0:
          DarkLightControl.setDarkMode();
          break;
      }
    } else {
      if (bright == Brightness.light) {
        DarkLightControl.setLightMode();
      } else {
        DarkLightControl.setDarkMode();

      }
    }
  }
}
