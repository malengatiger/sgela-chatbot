import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/ui/exam/exam_document_list.dart';
import 'package:edu_chatbot/ui/gemini/sections/gemini_multi_turn_chat_stream.dart';
import 'package:edu_chatbot/ui/image/image_picker_widget.dart';
import 'package:edu_chatbot/ui/landing_page.dart';
import 'package:edu_chatbot/ui/open_ai/open_ai_text_chat_widget.dart';
import 'package:edu_chatbot/ui/organization/organization_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:sgela_services/repositories/basic_repository.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/gemini_chat_service.dart';
import 'package:sgela_services/services/local_data_service.dart';
import 'package:sgela_services/services/mistral_client_service.dart';
import 'package:sgela_services/services/you_tube_service.dart';
import 'package:sgela_services/sgela_util/dark_light_control.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/color_gallery.dart';
import 'package:sgela_shared_widgets/widgets/org_logo_widget.dart';
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';

import '../../local_util/functions.dart';
import '../organization/organization_selector.dart';

class SubjectSearch extends StatefulWidget {
  const SubjectSearch({
    super.key,
  });

  @override
  SubjectSearchState createState() => SubjectSearchState();
}

class SubjectSearchState extends State<SubjectSearch> {
  final BasicRepository repository = GetIt.instance<BasicRepository>();
  final LocalDataService localDataService = GetIt.instance<LocalDataService>();
  final GeminiChatService chatService = GetIt.instance<GeminiChatService>();
  final YouTubeService youTubeService = GetIt.instance<YouTubeService>();
  final Prefs prefs = GetIt.instance<Prefs>();
  final FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  final ColorWatcher colorWatcher = GetIt.instance<ColorWatcher>();
  final DarkLightControl darkLightControl = GetIt.instance<DarkLightControl>();
  final Gemini gemini = GetIt.instance<Gemini>();

  final MistralServiceClient mistralServiceClient =
      GetIt.instance<MistralServiceClient>();
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
    // _testMistral();
  }

  Organization? sponsorOrganization;
  Sponsoree? sponsoree;

  _testMistral() async {
    pp('\n\n\n$mm ... sending hello to Mistral ....');
    try {
      //todo - remove after test
      var req = await mistralServiceClient.sendHello();
      pp('$mm response from Mistral: ${req?.toJson()}');
    } catch (e, s) {
      pp('$mm Mistral ERROR $e $s');
    }
  }

  _checkIfSponsored() async {
    pp('$mm ... checking if sponsored .....');
    sponsoree = prefs.getSponsoree();
    if (sponsoree == null) {
      pp('$mm ... checking if sponsored: NOT SPONSORED! navigateTo OrganizationSelector .....');
      Future.delayed(const Duration(milliseconds: 200), () async {
        var ok = await NavigationUtils.navigateToPage(
            context: context, widget: const OrganizationSelector());
        if (ok) {
          _getData();
        } else {
          _checkIfSponsored();
        }
      });
    } else {
      pp('$mm ... this user is SPONSORED! navigateTo OrganizationSplash for 5 seconds .....');
      _getData();
    }
  }

  void _getData() async {
    setState(() {
      busy = true;
    });
    try {
      await _getOrganization();
      await _getSubjects();
    } catch (e, s) {
      pp('$mm ERROR: $e - $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      busy = false;
    });
  }

  Future _getOrganization() async {
    sponsorOrganization = prefs.getOrganization();
    if (sponsorOrganization != null) {
      var brandings = await firestoreService.getOrganizationBrandings(
          sponsorOrganization!.id!, true);
      if (brandings.isNotEmpty) {
        branding = brandings.first;
        pp('$mm BRANDING, should show up at logo: ${branding!.toJson()}');
      }
    }
    currentAIModel = prefs.getCurrentModel();
    _selectedButton = {currentAIModel};
  }

  Future _getSubjects() async {
    _subjects = await firestoreService.getSubjects();
    _subjects.sort((a, b) => a.title!.compareTo(b.title!));
    _buildButtons();
    _arrangeSubjects();
    //_showHelpToast(10);
  }

  void _filterSubjects(String query) {
    _filteredSubjects = _subjects
        .where((subject) =>
            subject.title!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  _navigateToOrganizations() {
    NavigationUtils.navigateToPage(
        context: context, widget: const OrganizationSelector());
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
        const PopupMenuItem<String>(
          value: 'org',
          child: ListTile(
            leading: Icon(Icons.currency_exchange),
            title: Text('Sponsor Page'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'orgs',
          child: ListTile(
            leading: Icon(Icons.front_hand),
            title: Text('Sponsor Selection'),
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'info':
            _navigateToInfo();
            break;
          case 'colorGallery':
            _navigateToColorGallery();
            break;
          case 'org':
            _navigateToOrgSplash();
            break;
          case 'orgs':
            _navigateToOrganizations();
            break;
        }
      },
    );

    return popUp;
  }

  int mode = 0;
  List<Subject> favouriteSubjects = [];
  final ScrollController _scrollController = ScrollController();

  _showHelpToast(int delayInSeconds) async {
    if (mounted) {
      Future.delayed( Duration(seconds: delayInSeconds), () {
        showToast(
            backgroundColor: Colors.black,
            padding: 24,
            textStyle: const TextStyle(color: Colors.white),
            message: 'Double tap to move a Subject near the top of the list',
            toastGravity: ToastGravity.BOTTOM,
            duration: const Duration(milliseconds: 3000),
            context: context);
      });
    }
  }

  _saveFavouriteSubject(Subject subject) {
    showToast(
        backgroundColor: Colors.teal[700],
        padding: 20,
        textStyle: const TextStyle(color: Colors.white),
        message: '${subject.title} will be moved near the top of the list',
        duration: const Duration(seconds: 2),
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

  void _navigateToOrgSplash() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: const OrganizationSplash(
          doNotExpire: true,
        ));
  }

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context, widget: ColorGallery(colorWatcher: colorWatcher));
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

  void _navigateToClaudeMultiTurnChat() {
    prefs.saveCurrentModel(modelOpenAI);
    currentAIModel = modelOpenAI;
    NavigationUtils.navigateToPage(
        context: context, widget: const OpenAITextChatWidget());
  }

  _navigateToImagePicker() {
    NavigationUtils.navigateToPage(context: context, widget: ImagePickerWidget(chatService: chatService));
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
        value: modelAnthropic,
        label: Text(modelAnthropic, style: myTextStyleTiny(context))));

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
              fontWeight: FontWeight.normal,
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
              height: 28,
            ),
            leading: gapW4,
            actions: [
              IconButton(
                  onPressed: () {
                   _navigateToImagePicker();
                  },
                  icon: Icon(Icons.camera_alt,
                      color: isDark
                          ? Theme.of(context).primaryColor
                          : Colors.black)),
              IconButton(
                onPressed: () {
                  switch (currentAIModel) {
                    case modelGeminiAI:
                      _navigateToGeminiMultiTurnChat();
                      break;
                    case modelOpenAI:
                      _navigateToOpenAIMultiTurnChat();
                      break;
                    case modelAnthropic:
                      _navigateToClaudeMultiTurnChat();
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
                          pp('$mm ... ai model selection button selected: $sel');
                          if (sel.isNotEmpty) {
                            switch (sel.first) {
                              case modelGeminiAI:
                                currentAIModel = modelGeminiAI;
                                prefs.saveCurrentModel(modelGeminiAI);
                                break;
                              case modelOpenAI:
                                currentAIModel = modelOpenAI;
                                prefs.saveCurrentModel(modelOpenAI);
                                break;
                              case modelMistral:
                                showToast(
                                    message: 'Mistral model not available yet',
                                    context: context);
                                currentAIModel = modelGeminiAI;
                                prefs.saveCurrentModel(modelGeminiAI);
                                break;
                              case modelAnthropic:
                                showToast(
                                    message: 'Claude model not available yet',
                                    context: context);
                                currentAIModel = modelGeminiAI;
                                prefs.saveCurrentModel(modelGeminiAI);
                                break;
                              default:
                                currentAIModel = modelGeminiAI;
                                break;
                            }
                            _selectedButton = {currentAIModel};
                          } else {
                            _selectedButton = {modelGeminiAI};
                          }
                          setState(() {});
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () {
                          _showHelpToast(0);
                        },
                        icon: const Icon(Icons.question_mark, size: 16))
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
                        ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: BusyIndicator(
                              caption: 'Loading subjects ... just a second ...'),
                        )
                        : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView.builder(
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
                ),
                gapH8,
                GestureDetector(
                  onTap: () {
                    if (branding != null) {
                      NavigationUtils.navigateToPage(
                          context: context, widget: const OrganizationSplash());
                    }
                  },
                  child: const Card(
                    elevation: 8,
                    child: SponsoredBy(
                      logoHeight: 28,
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
}
