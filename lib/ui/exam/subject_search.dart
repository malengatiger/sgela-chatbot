import 'package:badges/badges.dart' as bd;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/gemini/sections/multi_turn_chat_stream.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/chat_gpt_service.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/color_gallery.dart';
import 'package:edu_chatbot/ui/exam/exam_document_list.dart';
import 'package:edu_chatbot/ui/organization/organization_splash.dart';
import 'package:edu_chatbot/ui/misc/powered_by.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get_it/get_it.dart';

import '../../data/branding.dart';
import '../../services/chat_service.dart';
import '../../services/local_data_service.dart';
import '../../services/you_tube_service.dart';
import '../../util/navigation_util.dart';
import '../../util/prefs.dart';
import '../image/image_picker_widget.dart';
import '../organization/organization_selector.dart';

class SubjectSearch extends StatefulWidget {


  const SubjectSearch(
      {super.key,});

  @override
  SubjectSearchState createState() => SubjectSearchState();
}

class SubjectSearchState extends State<SubjectSearch> {
  final Repository repository = GetIt.instance<Repository>();
  final LocalDataService localDataService = GetIt.instance<LocalDataService>();
  final ChatService chatService = GetIt.instance<ChatService>();
  final YouTubeService youTubeService = GetIt.instance<YouTubeService>();
  final Prefs prefs = GetIt.instance<Prefs>();
  final FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  final ColorWatcher colorWatcher = GetIt.instance<ColorWatcher>();
  final DarkLightControl darkLightControl = GetIt.instance<DarkLightControl>();
  final Gemini gemini = GetIt.instance<Gemini>();
  final TextEditingController _searchController = TextEditingController();
  List<Subject> _subjects = [];
  List<Subject> _filteredSubjects = [];
  bool busy = false, _showSearchBox = false;
  static const String mm = '🍎 🍎 🍎 SubjectSearch: ';
  Branding? branding;

  @override
  void initState() {
    super.initState();
    _checkIfSponsored();
  }

  Organization?  sponsorOrganization;

  _checkIfSponsored() async {
    sponsorOrganization = prefs.getOrganization();
    if (sponsorOrganization == null) {
      Future.delayed(const Duration(milliseconds: 200), () async {
        var ok = await NavigationUtils.navigateToPage(
            context: context, widget: const OrganizationSelector());
        if (ok) {
          _getSubjects();
          _getOrganization();
        } else {
          _checkIfSponsored();
        }
      });
    } else {
      _getSubjects();
      await _getOrganization();

      if (mounted) {
        if (branding != null) {
          NavigationUtils.navigateToPage(
              context: context,
              widget: OrganizationSplash(
                branding: branding!,
                timeToDisappear: branding!.splashTimeInSeconds == null
                    ? 5
                    : branding!.splashTimeInSeconds!,
              ));
        }
      }
    }
  }

  Future<void> _getOrganization() async {
    setState(() {
      busy = true;
    });
    try {
      //todo - 🍎🍎🍎 sort out the real implementation!!!
      sponsorOrganization = prefs.getOrganization();
      branding = prefs.getBrand();
      pp('$mm sponsorOrganization: ${sponsorOrganization!.toJson()}');
    } catch (e) {
      pp(e);

    }
    setState(() {
      busy = false;
    });
  }

  void _getSubjects() async {
    setState(() {
      busy = true;
    });
    try {
      _subjects = await firestoreService.getSubjects();
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
          chatService: chatService,
          examLink: null,
        ));
  }

  _callChatGPT() {
    pp('$mm _callChatGPT ............');
    var gpt = GetIt.instance<ChatGptService>();
    gpt.sendPrompt('Help me study for a Math test');
  }

  _navigateToExamsDocumentList(BuildContext context, Subject subject) {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ExamsDocumentList(
          subject: subject,
          repository: repository,
          localDataService: localDataService,
          chatService: chatService,
          youTubeService: youTubeService,
          colorWatcher: colorWatcher,
          gemini: gemini,
          prefs: prefs,
          firestoreService: firestoreService,
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
    var isDark =
        isDarkMode(prefs, MediaQuery.of(context).platformBrightness);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
                _callChatGPT();
              },
              child: branding == null
                  ? Text(
                      'SgelaAI',
                      style: myTextStyle(context,
                          Theme.of(context).primaryColor, 36, FontWeight.w900),
                    )
                  : Card(
                      elevation: 8,
                      child: CachedNetworkImage(
                        height: 36,
                        imageUrl: branding!.logoUrl!,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  _handleMode(MediaQuery.of(context).platformBrightness);
                },
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                    color:
                        isDark ? Theme.of(context).primaryColor : Colors.black),
              ),
              IconButton(
                  onPressed: () {
                    _navigateToAI(context);
                  },
                  icon: Icon(Icons.camera,
                      color: isDark
                          ? Theme.of(context).primaryColor
                          : Colors.black)),
              IconButton(
                onPressed: () {
                  _navigateToColorGallery();
                },
                icon: Icon(
                  Icons.color_lens_outlined,
                  color: isDark ? Theme.of(context).primaryColor : Colors.black,
                ),
              ),
              IconButton(
                onPressed: () {
                  _navigateToMultiTurnChat();
                },
                icon: Icon(
                  Icons.chat_outlined,
                  color: isDark ? Theme.of(context).primaryColor : Colors.black,
                ),
              ),
            ],
          ),
          // backgroundColor: bright == Brightness.light?Colors.brown.shade100:Colors.black,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _showSearchBox
                    ? Card(
                        elevation: 12,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              pp('🍎 🍎 ........ value: $value');
                              _filterSubjects(value);
                            },
                            // autofocus: false,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Search Subjects',
                                icon: Icon(Icons.search)),
                          ),
                        ),
                      )
                    : gapH32,
                const SizedBox(height: 4),
                Text(
                  'Subjects on board',
                  style: myTextStyle(context, Theme.of(context).primaryColor,
                      20, FontWeight.normal),
                ),
                gapH16,
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
                        ? const BusyIndicator(
                            caption: 'Loading subjects ... just a second ...')
                        : ListView.builder(
                            itemCount: _filteredSubjects.length,
                            itemBuilder: (context, index) {
                              Subject subject = _filteredSubjects[index];
                              return GestureDetector(
                                onTap: () {
                                  _navigateToExamsDocumentList(
                                      context, subject);
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
                gapH8,
                GestureDetector(
                  onTap: () {
                    if (branding != null) {
                      NavigationUtils.navigateToPage(
                          context: context,
                          widget: OrganizationSplash(branding: branding!));
                    }
                  },
                  child: Card(
                    elevation: 8,
                    child: PoweredBy(
                      repository: repository,
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

  _handleMode(Brightness bright) {
    var isDark = isDarkMode(prefs, bright);
    if (isDark) {
      darkLightControl.setLightMode();
    } else {
      darkLightControl.setDarkMode();
    }
  }

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ColorGallery(
            prefs: prefs, colorWatcher: colorWatcher));
  }
  void _navigateToMultiTurnChat() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: const MultiTurnStreamChat());
  }
}
