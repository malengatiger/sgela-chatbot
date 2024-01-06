import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:edu_chatbot/ui/color_gallery.dart';
import 'package:edu_chatbot/ui/exam_document_list.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/local_data_service.dart';
import '../services/you_tube_service.dart';
import '../util/navigation_util.dart';
import '../util/prefs.dart';
import 'image_picker_widget.dart';

class SubjectSearch extends StatefulWidget {
  final Repository repository;
  final LocalDataService localDataService;
  final ChatService chatService;
  final YouTubeService youTubeService;
  final Prefs prefs;
  final DownloaderService downloaderService;
  final ColorWatcher colorWatcher;
  final DarkLightControl darkLightControl;

  const SubjectSearch(
      {super.key,
      required this.repository,
      required this.localDataService,
      required this.chatService,
      required this.youTubeService,
      required this.downloaderService,
      required this.prefs,
      required this.colorWatcher,
      required this.darkLightControl});

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

  navigateToExamsDocumentList(BuildContext context, Subject subject) {
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
            title: Text(
              'SgelaAI',
              style: myTextStyle(
                  context, Theme.of(context).primaryColor, 24, FontWeight.w900),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await _handleMode(bright);
                },
                icon: Icon(mode == DARK ? Icons.light_mode : Icons.dark_mode,
                    color: Theme.of(context).primaryColor),
              ),
              IconButton(
                onPressed: () {
                  _navigateToAI(context);
                },
                icon: Icon(Icons.camera, color: Theme.of(context).primaryColor),
              ),
              IconButton(
                onPressed: () {
                  _showColorDialog();
                },
                icon: Icon(Icons.color_lens_outlined,
                    color: Theme.of(context).primaryColor),
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
                    child: busy
                        ? const BusyIndicator(caption: 'Loading subjects')
                        : ListView.builder(
                            itemCount: _filteredSubjects.length,
                            itemBuilder: (context, index) {
                              Subject subject = _filteredSubjects[index];
                              return GestureDetector(
                                onTap: () {
                                  navigateToExamsDocumentList(context, subject);
                                },
                                child: Card(
                                  elevation: 8,
                                  shape: getDefaultRoundedBorder(),
                                  child: ListTile(
                                    leading: Icon(Icons.ac_unit,
                                        color: Theme.of(context).primaryColor),
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
    mode = await prefs.getMode();
    if (mode > -1) {
      switch (mode) {
        case DARK:
          widget.darkLightControl.setLightMode();
          prefs.saveMode(LIGHT);
          break;
        case LIGHT:
          widget.darkLightControl.setDarkMode();
          prefs.saveMode(DARK);
          break;
      }
    } else {
      if (bright == Brightness.dark) {
        widget.darkLightControl.setLightMode();
      } else {
        widget.darkLightControl.setDarkMode();
      }
    }
  }

  void _showColorDialog() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Select Colour'),
            content: ColorGallery(
              prefs: widget.prefs,
              colorWatcher: widget.colorWatcher,
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close)),
            ],
          );
        });
  }
}
