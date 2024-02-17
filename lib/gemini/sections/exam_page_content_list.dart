import 'dart:typed_data';

import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/ui/chat/ai_model_selector.dart';
import 'package:edu_chatbot/ui/chat/gemini_image_chat_widget.dart';
import 'package:edu_chatbot/ui/chat/gemini_text_chat_widget.dart';
import 'package:edu_chatbot/ui/exam/pdf_viewer.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/ui/open_ai/open_ai_image_chat_widget.dart';
import 'package:edu_chatbot/ui/open_ai/open_ai_text_chat_widget.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../data/exam_page_content.dart';
import '../../ui/exam/exam_link_details.dart';
import '../../util/functions.dart';

class ExamPageContentSelector extends StatefulWidget {
  const ExamPageContentSelector(
      {super.key, required this.examLink, required this.aiModelName});

  final ExamLink examLink;
  final String aiModelName;

  @override
  State<ExamPageContentSelector> createState() =>
      ExamPageContentSelectorState();
}

class ExamPageContentSelectorState extends State<ExamPageContentSelector> {
  List<ExamPageContent> examPageContents = [];
  List<ExamPageContent> selectedExamPageContents = [];
  List<ContentBag> contentBags = [];
  Prefs prefs = GetIt.instance<Prefs>();
  LocalDataService localDataService = GetIt.instance<LocalDataService>();
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  Branding? branding;
  static const mm = '🍐🍐🍐🍐 ExamPageContentSelector 🍐';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _getPageContents();
  }

  _getPageContents() async {
    pp('$mm ... _getPageContents ...');
    setState(() {
      _busy = true;
    });
    try {
      branding = prefs.getBrand();
      examPageContents =
          await localDataService.getExamPageContents(widget.examLink.id!);
      if (examPageContents.isEmpty) {
        examPageContents =
            await firestoreService.getExamPageContents(widget.examLink.id!);
      }
      examPageContents.sort((a, b) => a.pageIndex!.compareTo(b.pageIndex!));
      for (var page in examPageContents) {
        contentBags.add(ContentBag(
            selected: false,
            examPageContent: page,
            maxLines: 1,
            charactersToShow: 360,
            height: 56));
      }
      _getImageCount();
      pp('$mm ... ${examPageContents.length} examPageContents found');
    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  //
  void _handleSelected() {
    selectedExamPageContents.clear();
    for (var bag in contentBags) {
      if (bag.selected) {
        selectedExamPageContents.add(bag.examPageContent);
      }
    }
    pp('$mm ... selectedExamPageContents: ${selectedExamPageContents.length}');
    selectedExamPageContents
        .sort((a, b) => a.pageIndex!.compareTo(b.pageIndex!));

    if (widget.aiModelName == modelGeminiAI) {
      if (_getImageCount() > 0) {
        NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiImageChatWidget(
                examLink: widget.examLink,
                examPageContents: selectedExamPageContents));
      } else {
        NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiTextChatWidget(
                examLink: widget.examLink,
                examPageContents: selectedExamPageContents));
      }
    } else {
      if (_getImageCount() > 0) {
        NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAIImageChatWidget(
                examLink: widget.examLink,
                examPageContents: selectedExamPageContents));
      } else {
        NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAIImageChatWidget(
                examLink: widget.examLink,
                examPageContents: selectedExamPageContents));
      }
    }
  }

  _handleLongPress(ContentBag bag) {
    showDialog(
        context: context,
        builder: (_) {
          var text = bag.examPageContent.text;
          Widget? mWidget;
          if (bag.examPageContent.pageImageUrl != null) {
            Uint8List uint8List =
                Uint8List.fromList(bag.examPageContent.uBytes!);
            mWidget = Image.memory(uint8List);
          } else {
            mWidget =
                Text(replaceKeywordsWithBlanks(bag.examPageContent.text!));
          }

          return AlertDialog(
            content: SingleChildScrollView(
                child: Column(
              children: [
                Text(
                  'Page ${bag.examPageContent.pageIndex! + 1}',
                  style: myTextStyleSmallBoldPrimaryColor(context),
                ),
                gapH16,
                mWidget,
              ],
            )),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close')),
              ElevatedButton(
                  style: const ButtonStyle(
                      elevation: MaterialStatePropertyAll(8.0)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToChat(bag);
                  },
                  child: const Text('Send to SgelaAI'))
            ],
          );
        });
  }

  int _getSelectedCount() {
    int cnt = 0;
    for (var value in contentBags) {
      if (value.selected) {
        cnt++;
      }
    }
    return cnt;
  }

  int imageCount = 0;

  int _getImageCount() {
    int cnt = 0;
    for (var value in contentBags) {
      if (value.examPageContent.pageImageUrl != null) {
        pp('$mm ... contentBag": image in the page, index: 🍎🍎${value.examPageContent.pageIndex} 🍎🍎');
        cnt++;
      }
    }
    imageCount = cnt;
    return imageCount;
  }

  String? modelName = 'Gemini Pro';

  String replaceKeywordsWithBlanks(String text) {
    String modifiedText = text
        .replaceAll("Copyright reserved", "")
        .replaceAll("Please turn over", "");
    return modifiedText;
  }

  bool _showHelp = false;

  void _navigateToChat(ContentBag bag) {
    pp('$mm handle choice of LLM model - Gemini or OpenAI. '
        '💜💜Current Model: ${widget.aiModelName} 💜💜');

    if (widget.aiModelName == modelGeminiAI) {
      if (_getImageCount() > 0) {
        NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiImageChatWidget(
                examLink: widget.examLink,
                examPageContents: [bag.examPageContent]));
      } else {
        NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiTextChatWidget(
                examLink: widget.examLink,
                examPageContents: [bag.examPageContent]));
      }
    } else {
      if (_getImageCount() > 0) {
        NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAIImageChatWidget(
                examLink: widget.examLink,
                examPageContents: [bag.examPageContent]));
      } else {
        NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAITextChatWidget(
                examLink: widget.examLink,
                examPageContents: [bag.examPageContent]));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int mode = prefs.getMode();
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: branding == null
            ? const Text('SgelaAI')
            : OrgLogoWidget(
                branding: branding,
                height: 24,
              ),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _showHelp = !_showHelp;
                });
              },
              icon: Icon(
                Icons.question_mark,
                color: mode == DARK
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              )),
          IconButton(
              onPressed: () {
                NavigationUtils.navigateToPage(
                    context: context,
                    widget: PDFViewer(
                        pdfUrl: widget.examLink.link!,
                        examLink: widget.examLink));
              },
              icon: Icon(Icons.file_download, color: mode == DARK
                  ? Theme.of(context).primaryColor
                  : Colors.black,)),
        ],
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(_showHelp ? 120.0 : 48.0),
            child: Column(
              children: [
                _showHelp
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showHelp = false;
                            });
                          },
                          child: Card(
                            elevation: 8,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 80,
                                child: Column(
                                  children: [
                                    const Text(
                                        'Tap once to select, double tap to de-select, '
                                        'long press to view contents '),
                                    gapH16,
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'AI model in play:',
                                          style: myTextStyleSmall(context),
                                        ),
                                        gapW8,
                                        Text(
                                          widget.aiModelName,
                                          style: myTextStyle(
                                              context,
                                              Theme.of(context).primaryColor,
                                              16,
                                              FontWeight.w900),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : gapH4,
                gapH8,
              ],
            )),
      ),
      body: ScreenTypeLayout.builder(
        mobile: (_) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        gapH16,
                        Text(
                          'Exam Paper Pages',
                          style: myTextStyleMediumLargeWithSize(context, 24),
                        ),
                        ExamLinkDetails(
                            examLink: widget.examLink, pageNumber: 0),
                        gapH32,
                        Expanded(
                          child: _busy
                              ? const BusyIndicator(
                                  caption: 'Loading exam paper pages',
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: bd.Badge(
                                    position: bd.BadgePosition.topEnd(
                                        top: -8, end: -4),
                                    badgeContent:
                                        Text('${_getSelectedCount()}'),
                                    child: GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3),
                                        itemCount: contentBags.length,
                                        itemBuilder: (_, index) {
                                          var contentBag =
                                              contentBags.elementAt(index);
                                          return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  contentBag.selected = true;
                                                  contentBag.height = 52.0;
                                                  contentBag.charactersToShow =
                                                      260;
                                                  contentBag.maxLines = 3;
                                                });
                                              },
                                              onLongPress: () {
                                                pp('$mm ... onLongPress ...');
                                                setState(() {
                                                  contentBag.selected = true;
                                                });
                                                _handleLongPress(contentBag);
                                              },
                                              onDoubleTap: () {
                                                setState(() {
                                                  contentBag.selected = false;
                                                  contentBag.height = 40.0;
                                                  contentBag.charactersToShow =
                                                      80;
                                                  contentBag.maxLines = 1;
                                                });
                                              },
                                              child: ExamPageContentCard(
                                                contentBag: contentBag,
                                              ));
                                        }),
                                  ),
                                ),
                        ),
                        if (_getSelectedCount() > 0)
                          SizedBox(
                            width: 320,
                            height: 100,
                            child: Column(
                              children: [
                                gapH32,
                                ElevatedButton(
                                    style: const ButtonStyle(
                                        elevation:
                                            MaterialStatePropertyAll(16.0)),
                                    onPressed: () {
                                      _handleSelected();
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('Send Page(s) to Sgela AI'),
                                    )),
                              ],
                            ),
                          ),
                        gapH32,
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                  bottom: 8,
                  left: 48,
                  right: 48,
                  child: SponsoredBy(
                    logoHeight: 24,
                  )),
            ],
          );
        },
        tablet: (_) {
          return const Stack();
        },
        desktop: (_) {
          return const Stack();
        },
      ),
    ));
  }
}

class ExamPageContentCard extends StatelessWidget {
  const ExamPageContentCard({super.key, required this.contentBag, this.mode});

  final ContentBag contentBag;
  final int? mode;

  @override
  Widget build(BuildContext context) {
    if (mode == null) {
      mode == DARK;
    }
    return Card(
      elevation: 8,
      child: SizedBox(
        height: contentBag.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                contentBag.selected
                    ? Checkbox(
                        value: contentBag.selected,
                        activeColor: Colors.green,
                        onChanged: (selected) {})
                    : gapW16,
                Text(
                  'Page',
                  style: myTextStyleTiny(context),
                ),
                gapW4,
                Text(
                  '${contentBag.examPageContent.pageIndex! + 1}',
                  style: myTextStyle(
                      context,
                      contentBag.selected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColorLight,
                      20,
                      contentBag.selected
                          ? FontWeight.w900
                          : FontWeight.normal),
                ),
              ],
            ),
            gapH8,
            contentBag.examPageContent.pageImageUrl == null
                ? gapW4
                : Icon(Icons.camera_alt,
                    size: 18, color: Theme.of(context).primaryColor)
          ],
        ),
      ),
    );
  }
}

class ContentBag {
  late bool selected;
  late ExamPageContent examPageContent;
  late int maxLines;
  late double height;
  late int charactersToShow;

  ContentBag(
      {required this.selected,
      required this.examPageContent,
      required this.maxLines,
      required this.charactersToShow,
      required this.height});
}
