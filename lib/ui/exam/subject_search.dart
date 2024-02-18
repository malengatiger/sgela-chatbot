import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/sponsoree.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/gemini/sections/gemini_multi_turn_chat_stream.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/chat_gpt_service.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/ui/chat/ai_model_selector.dart';
import 'package:edu_chatbot/ui/exam/exam_document_list.dart';
import 'package:edu_chatbot/ui/landing_page.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/color_gallery.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/ui/open_ai/open_ai_text_chat_widget.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/ui/organization/organization_splash.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get_it/get_it.dart';

import '../../data/branding.dart';
import '../../services/gemini_chat_service.dart';
import '../../services/local_data_service.dart';
import '../../services/you_tube_service.dart';
import '../../util/navigation_util.dart';
import '../../util/prefs.dart';
import '../image/image_picker_widget.dart';
import '../organization/organization_selector.dart';

class SubjectSearch extends StatefulWidget {
  const SubjectSearch({
    super.key,
  });

  @override
  SubjectSearchState createState() => SubjectSearchState();
}

class SubjectSearchState extends State<SubjectSearch> {
  final Repository repository = GetIt.instance<Repository>();
  final LocalDataService localDataService = GetIt.instance<LocalDataService>();
  final GeminiChatService chatService = GetIt.instance<GeminiChatService>();
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
  static const String mm = '🍎🍎🍎🍎🍎🍎 SubjectSearch: 🍎🍎🍎 ';
  Branding? branding;

  Set<String> _selectedButton = {modelGeminiAI};

  @override
  void initState() {
    super.initState();
    _checkIfSponsored();
  }

  Organization? sponsorOrganization;
  Sponsoree? sponsoree;

  _checkIfSponsored() async {
    pp('$mm ... checking if sponsored .....');
    sponsoree = prefs.getSponsoree();
    if (sponsoree == null) {
      pp('$mm ... checking if sponsored: NOT SPONSORED! navigateTo OrganizationSelector .....');
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
      pp('$mm ... this user is SPONSORED! navigateTo OrganizationSplash for 5 seconds .....');
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
      sponsorOrganization = prefs.getOrganization();
      branding = prefs.getBrand();
      currentAIModel = prefs.getCurrentModel();
      _selectedButton = {currentAIModel};
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
      _buildButtons();
      _arrangeSubjects();
      _showHelpToast();
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


  _navigateToExamsDocumentList(BuildContext context, Subject subject) {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ExamsDocumentList(
          subject: subject,
          repository: repository,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PopupMenuButton _getMenuButton(bool isDark) {
    List<PopupMenuItem<int>> items = [];

    var popUp = PopupMenuButton<String>(
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'colorGallery',
          child: ListTile(
            leading: Icon(Icons.color_lens_outlined),
            title: Text('Pick your Colour'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'info',
          child: ListTile(
            leading: Icon(Icons.question_mark),
            title: Text('Information'),
          ),
        ),
      ],
      onSelected: (String value) {
        if (value == 'info') {
          _navigateToInfo();
        } else if (value == 'colorGallery') {
          _navigateToColorGallery();
        }
      },
    );

    return popUp;
  }

  int mode = 0;
  List<Subject> favouriteSubjects = [];
  final ScrollController _scrollController = ScrollController();

  _showHelpToast() async {

    if (mounted) {
      showToast(
          backgroundColor: Colors.black,
          padding: 24,
          textStyle: const TextStyle(color: Colors.white),
          message: 'Double tap to move a Subject near the top of the list',
          context: context);
    }
  }

  _saveFavouriteSubject(Subject subject) {
    showToast(
        backgroundColor: Colors.teal[700],
        padding: 20,
        textStyle: const TextStyle(color: Colors.white),
        message: 'Subject is a favourite: ${subject.title}',
        context: context);

    favouriteSubjects = prefs.getSubjects();
    bool found = false;
    for (var sub in favouriteSubjects) {
      if (subject.title == sub.title) {
        found = true;
      }
    }
    if (!found) {
      prefs.saveSubject(subject);
    }
    _arrangeSubjects();
    setState(() {});
  }

  void _arrangeSubjects() {
    favouriteSubjects = prefs.getSubjects();
    _filteredSubjects.clear();
    _filteredSubjects.addAll(favouriteSubjects);

    for (var sub in _subjects) {
      bool found = false;
      for (var fav in favouriteSubjects) {
        if (fav.title == sub.title) {
          found = true;
        }
      }
      if (!found) {
        _filteredSubjects.add(sub);
      }
    }
    pp('$mm ...... _filteredSubjects: ${_filteredSubjects.length}');
  }

  void _navigateToInfo() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: const LandingPage(
          hideButtons: true,
        ));
  }

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ColorGallery(prefs: prefs, colorWatcher: colorWatcher));
  }

  void _navigateToGeminiMultiTurnChat() {
    prefs.saveCurrentModel(modelGeminiAI);
    currentAIModel = modelGeminiAI;
    NavigationUtils.navigateToPage(
        context: context, widget: const GeminiMultiTurnStreamChat());
  }

  void _navigateToOpenAIMultiTurnChat() {
    prefs.saveCurrentModel(modelOpenAI);
    currentAIModel = modelOpenAI;
    NavigationUtils.navigateToPage(
        context: context, widget: const OpenAITextChatWidget());
  }

  String currentAIModel = modelGeminiAI;
  List<ButtonSegment<String>> buttons = [];

  _buildButtons() {
    buttons.add(ButtonSegment(
        value: modelGeminiAI,
        label: Text(
          modelGeminiAI,
          style: myTextStyleTiny(context),
        )));
    buttons.add(ButtonSegment(
        value: modelOpenAI,
        label: Text(modelOpenAI, style: myTextStyleTiny(context))));
    buttons.add(ButtonSegment(
        value: modelMistral,
        label: Text(modelMistral, style: myTextStyleTiny(context))));
  }
  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w900,
            );
    var isDark = isDarkMode(prefs, MediaQuery.of(context).platformBrightness);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: OrgLogoWidget(
              branding: branding,
              height: 24,
            ),
            leading: gapW4,
            actions: [
              IconButton(
                  onPressed: () {
                    switch (currentAIModel) {
                      case modelGeminiAI:
                        _navigateToGeminiMultiTurnChat();
                        break;
                      case modelOpenAI:
                        _navigateToOpenAIMultiTurnChat();
                        break;
                      default:
                        _navigateToGeminiMultiTurnChat();
                        break;
                    }
                  },
                  icon: Icon(Icons.camera_alt,
                      color: isDark
                          ? Theme.of(context).primaryColor
                          : Colors.black)),
              IconButton(
                onPressed: () {
                 switch(currentAIModel) {
                   case modelGeminiAI:
                     _navigateToGeminiMultiTurnChat();
                     break;
                   case modelOpenAI:
                     _navigateToOpenAIMultiTurnChat();
                     break;
                   default:
                     _navigateToGeminiMultiTurnChat();
                     break;
                 }
                },
                icon: Icon(
                  Icons.chat_outlined,
                  color: isDark ? Theme.of(context).primaryColor : Colors.black,
                ),
              ),
              _getMenuButton(isDark),
            ],
          ),
          // backgroundColor: bright == Brightness.light?Colors.brown.shade100:Colors.black,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                gapH32,
                buttons.isEmpty
                    ? gapW4
                    : SegmentedButton(
                        emptySelectionAllowed: true,
                        segments: buttons,
                        onSelectionChanged: (sel) {
                          pp('$mm ... button selected: $sel');

                          switch (sel.first) {
                            case modelGeminiAI:
                              currentAIModel = modelGeminiAI;
                              break;
                            case modelOpenAI:
                              currentAIModel = modelOpenAI;
                              break;
                            case modelMistral:
                              showToast(
                                  message: 'Mistral model not available yet',
                                  context: context);
                              setState(() {
                                _selectedButton = {modelGeminiAI};
                              });
                              break;
                            default:
                              currentAIModel = modelGeminiAI;
                          }
                          setState(() {
                            _selectedButton = sel;
                          });
                        },
                        selected: _selectedButton,
                      ),
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
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Subjects Exams on board',
                      style: myTextStyle(context, Theme.of(context).primaryColor,
                          16, FontWeight.w900),
                    ),
                    gapW32,
                    IconButton(onPressed: (){
                      _showHelpToast();
                    }, icon: const Icon(Icons.question_mark))
                  ],
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
                            controller: _scrollController,
                            itemBuilder: (context, index) {
                              Subject subject = _filteredSubjects[index];
                              return GestureDetector(
                                onTap: () {
                                  _navigateToExamsDocumentList(
                                      context, subject);
                                },
                                onDoubleTap: () {
                                  _saveFavouriteSubject(subject);
                                  scrollToTop();
                                },
                                child: Card(
                                  elevation: 8,
                                  shape: getDefaultRoundedBorder(),
                                  child: ListTile(
                                    leading: Icon(Icons.ac_unit,
                                        color: Theme.of(context).primaryColor),
                                    title: Row(
                                      children: [
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            '${index + 1}',
                                            style: myTextStyle(
                                                context,
                                                Theme.of(context).primaryColor,
                                                16,
                                                FontWeight.bold),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            subject.title ?? '',
                                            style: titleStyle,
                                          ),
                                        ),
                                      ],
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
                  child: const Card(
                    elevation: 8,
                    child: SponsoredBy(logoHeight: 20,),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
