import 'dart:typed_data';

import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/gemini/sections/gemini_multi_turn_chat_stream.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/ui/chat/ai_model_selector.dart';
import 'package:edu_chatbot/ui/chat/gemini_image_chat_widget.dart';
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
  const ExamPageContentSelector({super.key, required this.examLink});

  final ExamLink examLink;

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
  late String aiModel;

  @override
  void initState() {
    super.initState();
    aiModel = prefs.getCurrentModel();
    _getPageContents();
  }

  _getPageContents() async {
    pp('$mm ... _getPageContents ...');
    setState(() {
      _busy = true;
    });
    try {
      aiModel = prefs.getCurrentModel();
      branding = prefs.getBrand();
      examPageContents =
          await firestoreService.getExamPageContents(widget.examLink.id!);
      examPageContents.sort((a, b) => a.pageIndex!.compareTo(b.pageIndex!));

      for (var page in examPageContents) {
        contentBags.add(ContentBag(
            selected: false,
            examPageContent: page,
            maxLines: 1,
            charactersToShow: 360,
            height: 56));
      }
      var cnt = _getImageCount();
      pp('$mm ... ${examPageContents.length} examPageContents found, images: $cnt');
    } catch (e, s) {
      pp("$mm $s $e");
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  //

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
                    _navigateToChat();
                  },
                  child: const Text('Send to SgelaAI'))
            ],
          );
        });
  }

  int _getSelectedCount() {
    int cnt = 0;
    for (var bag in contentBags) {
      if (bag.selected) {
        cnt++;
      }
    }
    return cnt;
  }

  List<ContentBag> selectedBags = [];

  int imageCount = 0;

  int _getImageCount() {
    int cnt = 0;
    for (var value in contentBags) {
      if (value.examPageContent.pageImageUrl != null &&
          value.examPageContent.pageIndex! > 0) {
        cnt++;
      }
    }
    imageCount = cnt;
    return imageCount;
  }

  String? modelName = modelGeminiAI;

  String replaceKeywordsWithBlanks(String text) {
    String modifiedText = text
        .replaceAll("Copyright reserved", "")
        .replaceAll("Please turn over", "");
    return modifiedText;
  }

  bool _showHelp = false;

  void _navigateToChat() {
    pp('$mm ... _navigateToChat ..... selectedBags: ${selectedBags.length}');
    var aiModelName = prefs.getCurrentModel();
    List<ExamPageContent> mPages = [];
    for (var bag in selectedBags) {
      if (bag.examPageContent.pageIndex == 0 &&
          bag.examPageContent.pageImageUrl != null) {
        continue;
      }
      mPages.add(bag.examPageContent);
    }
    if (aiModelName == modelGeminiAI) {
      _goToGemini(mPages);
    } else if (aiModelName == modelOpenAI) {
      _goToOpenAI(mPages);
    } else if (aiModelName == modelMistral) {
      _goToGemini(mPages);
    }
  }

  void _goToOpenAI(List<ExamPageContent> mPages) async {
    pp('$mm ... geToOpenAI ..... contentPages: ${mPages.length}');
    if (mPages.isEmpty) {
      _showNoPagesToast();
      return;
    }
    _clearSelected();

    for (var page in mPages) {
      if (page.pageImageUrl != null) {
        pp('$mm ... go to OpenAIImageChatWidget ..... page index: ${page.pageIndex}');
        await NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAIImageChatWidget(
              examPageContents: [page],
              examLink: widget.examLink,
            ));
      } else {
        pp('$mm ... go to OpenAITextChatWidget ..... page index: ${page.pageIndex}');

        await NavigationUtils.navigateToPage(
            context: context,
            widget: OpenAITextChatWidget(examPageContents: [page]));
      }
    }
  }

  _showNoPagesToast() {
    showToast(
        duration: const Duration(seconds: 3),
        message: 'No content to send, this may be the first cover page', context: context);
    _clearSelected();
  }
  Future<void> _goToGemini(List<ExamPageContent> mPages) async {
    pp('$mm ... _goToGemini..... contentPages: ${mPages.length}');
    if (mPages.isEmpty) {
      _showNoPagesToast();
      return;
    }
    _clearSelected();
    for (var page in mPages) {
      if (page.pageImageUrl != null) {
        pp('$mm ... go to GeminiImageChatWidget ..... page index: ${page.pageIndex}');

        await NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiImageChatWidget(
                examLink: widget.examLink, examPageContents: [page]));
      } else {
        pp('$mm ... go to GeminiMultiTurnStreamChat ..... page index: ${page.pageIndex}');

        await NavigationUtils.navigateToPage(
            context: context,
            widget: GeminiMultiTurnStreamChat(
                examLink: widget.examLink, examPageContents: [page]));
      }
    }
  }

  void _clearSelected() {
    for (var element in contentBags) {
      element.selected = false;
    }
    setState(() {
      selectedBags.clear();
    });
  }


  _showModelDialog() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
             title:  Text('AI Model Selection', style: myTextStyleMedium(context),),
              content: SizedBox(
            height: 300,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                        onTap: () {
                          prefs.saveCurrentModel(modelGeminiAI);
                          Navigator.of(context).pop();
                          _showResult(modelGeminiAI);
                          setState(() {
                            aiModel = modelGeminiAI;
                          });
                        },
                        child: Text(
                          modelGeminiAI,
                          style: myTextStyleMediumLargePrimaryColor(context),
                        )),
                    gapH32,
                    GestureDetector(
                        onTap: () {
                          prefs.saveCurrentModel(modelOpenAI);
                          Navigator.of(context).pop();
                          _showResult(modelOpenAI);
                          setState(() {
                            aiModel = modelOpenAI;
                          });
                        },
                        child: Text(modelOpenAI,
                            style: myTextStyleMediumLargePrimaryColor(context, ))),
                  ],
                ),
              ),
            ),
          ));
        });
  }

  _showResult(String model) {
    showToast(
        duration: const Duration(seconds: 2),
        message: 'AI Model selected: $model', context: context);
  }
  _addToSelected(ContentBag contentBag) {
    bool found = false;
    for (var element in selectedBags) {
      if (contentBag.examPageContent.pageIndex == element.examPageContent.pageIndex) {
        found = true;
      }
    }
    if (!found) {
      selectedBags.add(contentBag);
    }
  }
  _removeContentBag(ContentBag contentBag) {
    selectedBags.remove(contentBag);
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
                _showModelDialog();
              },
              icon: Icon(
                Icons.ac_unit,
                color: mode == DARK
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              )),
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
              icon: Icon(
                Icons.file_download,
                color: mode == DARK
                    ? Theme.of(context).primaryColor
                    : Colors.black,
              )),
        ],
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(_showHelp ? 160.0 : 8.0),
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
                                height: 120,
                                child: Column(
                                  children: [
                                    gapH16,
                                    const Text(
                                        'Tap the list once to select an exam page, double tap to de-select, '
                                        'long press to view the page content. '),
                                    gapH16,
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Artificial Intelligence model:',
                                          style: myTextStyleSmall(context),
                                        ),
                                        gapW8,
                                        Text(
                                          aiModel,
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
                                    badgeStyle: const bd.BadgeStyle(
                                      padding: EdgeInsets.all(12),
                                    ),
                                    position: bd.BadgePosition.topEnd(
                                        top: -8, end: -4),
                                    badgeContent:
                                        Text('${selectedBags.length}'),
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
                                                pp('$mm ... onTap ... contentBag, pageIndex: '
                                                    '${contentBag.examPageContent.pageIndex}');
                                                _addToSelected(contentBag);
                                                setState(() {
                                                  contentBag.selected = true;
                                                  contentBag.height = 52.0;
                                                  contentBag.charactersToShow =
                                                      260;
                                                  contentBag.maxLines = 3;
                                                  pp('$mm ... onTap: selectedBags: ${selectedBags.length}');
                                                });
                                              },
                                              onLongPress: () {
                                                pp('$mm ... onLongPress ... contentBag, pageIndex: '
                                                    '${contentBag.examPageContent.pageIndex}');
                                                _addToSelected(contentBag);
                                                setState(() {
                                                  contentBag.selected = true;
                                                });
                                                _handleLongPress(contentBag);
                                              },
                                              onDoubleTap: () {
                                                pp('$mm ... onDoubleTap ... contentBag, pageIndex: '
                                                    '${contentBag.examPageContent.pageIndex}');
                                                _removeContentBag(contentBag);
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
                            width: 400,
                            height: 100,
                            child: Column(
                              children: [
                                gapH32,
                                ElevatedButton(
                                    style: const ButtonStyle(
                                        elevation:
                                            MaterialStatePropertyAll(16.0)),
                                    onPressed: () {
                                      _navigateToChat();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text('Send ${selectedBags.length} '
                                          'Page(s) to Sgela AI'),
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
