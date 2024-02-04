import 'dart:typed_data';

import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/open_ai/open_ai_driver.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../data/exam_page_content.dart';
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
      _showToast();
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

    NavigationUtils.navigateToPage(
        context: context,
        widget: AICommunicationsWidget(
            examLink: widget.examLink,
            examPageContents: selectedExamPageContents));
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
            mWidget = Text(replaceKeywordsWithBlanks(bag.examPageContent.text!));
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
                    NavigationUtils.navigateToPage(
                        context: context,
                        widget: AICommunicationsWidget(
                            examLink: widget.examLink,
                            examPageContents: [bag.examPageContent]));
                  },
                  child: const Text('Send to SgelaAI'))
            ],
          );
        });
  }

  void _showToast() {
    Future.delayed(const Duration(milliseconds: 200), () {
      showToast(
          padding: 20,
          backgroundColor: Colors.black,
          toastGravity: ToastGravity.TOP,
          duration: const Duration(seconds: 10),
          textStyle: const TextStyle(color: Colors.white),
          message: 'Tap once to select, double tap to de-select, '
              'long press to view contents of the page',
          context: context);
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
  String replaceKeywordsWithBlanks(String text) {
    String modifiedText = text.replaceAll("Copyright reserved", "")
        .replaceAll("Please turn over", "");
    return modifiedText;
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: branding == null
            ? const Text('SgelaAI')
            : OrgLogoWidget(
                branding: branding,
              ),
        actions: [
          IconButton(
              onPressed: () {
                _showToast();
              },
              icon: const Icon(Icons.question_mark)),
        ],
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
              )
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
  const ExamPageContentCard({super.key, required this.contentBag});

  final ContentBag contentBag;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: SizedBox(
        height: contentBag.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            contentBag.selected
                ? Checkbox(
                    value: contentBag.selected,
                    activeColor: Colors.green,
                    onChanged: (selected) {})
                : gapW16,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
