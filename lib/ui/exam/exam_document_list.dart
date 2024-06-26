import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/ui/exam/exam_link_list_widget.dart';
import 'package:edu_chatbot/ui/gemini/sections/gemini_multi_turn_chat_stream.dart';
import 'package:edu_chatbot/ui/groq/groq_chat_stream.dart';
import 'package:edu_chatbot/ui/open_ai/open_ai_text_chat_widget.dart';
import 'package:edu_chatbot/ui/youtube/you_tube_searcher.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/exam_document.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:sgela_services/repositories/basic_repository.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/openai_assistant_service.dart';
import 'package:sgela_services/sgela_util/dark_light_control.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/color_gallery.dart';
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';

import '../../local_util/functions.dart';
import '../chat/model_chooser.dart' as chooser;

class ExamsDocumentList extends StatefulWidget {
  const ExamsDocumentList({
    super.key,
    required this.repository,
    required this.subject,
  });

  final BasicRepository repository;
  final Subject subject;

  @override
  ExamsDocumentListState createState() => ExamsDocumentListState();
}

class ExamsDocumentListState extends State<ExamsDocumentList> {
  static const mm = '🔵🔵🔵🔵ExamsDocumentList';

  @override
  void initState() {
    super.initState();
    _fetchExamDocuments();
  }

  bool busy = false;
  List<ExamDocument> examDocs = [];
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  Prefs prefs = GetIt.instance<Prefs>();
  ColorWatcher colorWatcher = GetIt.instance<ColorWatcher>();

  _fetchExamDocuments() async {
    try {
      setState(() {
        busy = true;
      });
      examDocs = await firestoreService.getExamDocuments();
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

  _navigateToExamLinks(ExamDocument examDocument) async {
    if (mounted) {
      NavigationUtils.navigateToPage(
          context: context,
          widget: ExamLinkListWidget(
            subject: widget.subject,
            examDocument: examDocument,
          ));
    }
  }

  void _navigateToYouTube() {
    pp('$mm _navigateToYouTube ... widget.subject.id: ${widget.subject.id}');
    NavigationUtils.navigateToPage(
        context: context,
        widget: YouTubeSearcher(
          subject: widget.subject,
        ));
  }

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context, widget: ColorGallery(colorWatcher: colorWatcher));
  }

  void _navigateToChat() {
    var aiModel = prefs.getCurrentModel();
    pp('$mm ... _navigateToChat, model: $aiModel');
    
    switch (aiModel) {
      case modelGeminiAI:
        NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiMultiTurnStreamChat(
              subject: widget.subject,
            ));
        break;
      case modelOpenAI:
        NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAITextChatWidget(
              subject: widget.subject,
            ));
        break;
      case modelMistral:
        showToast(message: '$modelMistral not available yet', context: context);
        break;
      case modelClaude:
        showToast(message: '$modelClaude not available yet', context: context);
        break;
      case modelMixtral:
        pp('$mm ... go to GroqChat ..... ');
        NavigationUtils.navigateToPage(
            context: context,
            widget: GroqChat(
              subject: widget.subject,
            ));
        break;
      case modelLlama2:
        showToast(message: '$modelLlama2 not available yet', context: context);
        break;
      default:
        NavigationUtils.navigateToPage(
            context: context,
            widget: GroqChat(
              subject: widget.subject,
            ));
        break;
    }
  }

  OpenAIAssistantService assistantService =
      GetIt.instance<OpenAIAssistantService>();
  String? aiModel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text(''),
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
                        color: Theme.of(context).primaryColor)),
                IconButton(
                    onPressed: () {
                      _navigateToChat();
                    },
                    icon: Icon(Icons.message_outlined,
                        color: Theme.of(context).primaryColor)),
                Card(
                  elevation: 16,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16, top: 8, bottom: 8),
                    child: chooser.ModelChooser(
                      onSelected: (model) {
                        setState(() {
                          aiModel = model;
                        });
                      },
                    ),
                  ),
                ),
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
                      gapH32,
                      Expanded(
                        child: busy
                            ? const BusyIndicator(
                                caption:
                                    "Loading exam documents. Gimme a second ...",
                              )
                            : Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: bd.Badge(
                                  badgeContent: Text('${examDocs.length}'),
                                  badgeStyle: const bd.BadgeStyle(
                                    badgeColor: Colors.purple,
                                    padding: EdgeInsets.all(12),
                                  ),
                                  child: ListView.builder(
                                      itemCount: examDocs.length,
                                      itemBuilder: (_, index) {
                                        var examDocument =
                                            examDocs.elementAt(index);
                                        return GestureDetector(
                                          onTap: () {
                                            _navigateToExamLinks(examDocument);
                                          },
                                          child: Card(
                                            elevation: 8,
                                            child: ListTile(
                                              title: Text(
                                                '${examDocument.title}',
                                                style:
                                                    myTextStyleSmall(context),
                                              ),
                                              leading: Icon(Icons.edit_note,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            ),
                                          ),
                                        );
                                      }),
                                ),
                              ),
                      ),
                      const SponsoredBy(),
                    ],
                  ),
                )
              ],
            )));
  }
}
