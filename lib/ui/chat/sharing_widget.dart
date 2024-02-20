import 'dart:io';
import 'dart:typed_data';

import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/services/conversion_service.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:sgela_services/sgela_util/Converter.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mailer/mailer.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:badges/badges.dart' as bd;

import '../../local_util/functions.dart';
class SharingWidget extends StatefulWidget {
  const SharingWidget(
      {super.key,
      required this.examPageContents,
      required this.aiResponseText,
      required this.examLink});

  final List<ExamPageContent> examPageContents;
  final String aiResponseText;
  final ExamLink examLink;

  @override
  SharingWidgetState createState() => SharingWidgetState();
}

class SharingWidgetState extends State<SharingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Country? country;
  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  static const mm = '🔵🔵🔵🔵 SharingWidget  🔵🔵';
  ConversionService conversionService = GetIt.instance<ConversionService>();

  File? responseFileHTML, responseFilePDF;
  Branding? branding;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  bool _busy = false;

  _getData() async {
    pp('$mm ..................... converting response to html ...');
    setState(() {
      _busy = false;
    });
    try {
      _buildTitle();
      organization = prefs.getOrganization();
      branding = prefs.getBrand();
      if ((isValidLaTeXString(widget.aiResponseText))) {
        responseFileHTML = await conversionService.convertToHtmlFromLaTeX(
            widget.aiResponseText, title!,widget.examLink.title!);
        responseFilePDF = await conversionService.convertToPdfFromLaTeX(
            widget.aiResponseText, title!,widget.examLink.title!);
      } else {
        responseFileHTML = await conversionService.convertToHtmlFromMarkdown(
            widget.aiResponseText, title!,widget.examLink.title!);
        responseFilePDF = await conversionService.convertToPdfFromMarkdown(
            widget.aiResponseText, title!,widget.examLink.title!);
      }
      if (responseFileHTML != null) {
        pp('$mm ... responseFileHTML: ${responseFileHTML!.path} - '
            '${await responseFileHTML!.length()} bytes...');
      }
      if (responseFilePDF != null) {
        pp('$mm ... responseFilePDF: ${responseFilePDF!.path} - '
            '${await responseFilePDF!.length()} bytes...');
      }
      //
      _buildImages();
      _buildQuestionHTML();
      _buildPageWidgets();

    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  String? questionHTML, title;

  _buildImages() {
    for (var pageContent in widget.examPageContents) {
      if (pageContent.uBytes != null) {
        images.add(Uint8List.fromList(pageContent.uBytes!));
      }
    }
  }

  _buildQuestionHTML() {
    var sb = StringBuffer();
    sb.write('<h1>${widget.examLink.documentTitle}</h1>\n');
    sb.write('<h2>${widget.examLink.title}</h2>\n');

    var sb2 = StringBuffer();
    for (var value in widget.examPageContents) {
      if (value.text != null) {
        sb2.write(value.text!);
      }
    }
    if ((sb2.isEmpty)) {
      return;
    }
    sb.write(sb2.toString());
    questionHTML = sb.toString();
  }

  _buildTitle() {
    var sb = StringBuffer();
    sb.write('${widget.examLink.documentTitle}\n');
    sb.write('${widget.examLink.title}\n');

    var sb2 = StringBuffer();
    for (var value in widget.examPageContents) {
      if (value.pageIndex != null) {
        sb2.write('Page ${value.pageIndex! + 1} ');
      }
    }
    //
    sb.write(sb2.toString());
    title = sb.toString();
  }

  List<Uint8List> images = [];
  bool _hasCallSupport = false;
  _shareAIResponse() async {
    pp('$mm ........................... _shareAIResponse .....');
//https://api.whatsapp.com/send?phone=XXXXXXXXXXX

    canLaunchUrl(Uri(scheme: 'tel', path: '27655917675')).then((bool result) {
      setState(() {
        _hasCallSupport = result;
      });
    });
    var files = Converter.convertUint8ListToFiles(images);

    if (responseFilePDF != null) {
      files.add(responseFilePDF!);
    }

    List<XFile> xFiles = Converter.convertFilesToXFiles(files);
    pp('$mm ..... Sharing ${xFiles.length} xFiles ....');

    try {
      setState(() {
        _busy = true;
      });
      final box = context.findRenderObject() as RenderBox?;
      final result = await Share.shareXFiles(xFiles,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          text: '${widget.examLink.documentTitle} - ${widget.examLink.title}');
      if (result.status == ShareResultStatus.success) {
        pp('$mm Thank you for sharing the response package!');
      }
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
_sendEmailToSelf() {
    var msg = Message();
    msg.from(const Address('malengadev@gmail.com'));
    msg.recipients = ([const Address('malengadev@gmail.com')]);
    msg.subject = 'Testing 123';


}
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PageController pageController = PageController();
  WebViewController questionWebViewController = WebViewController();
  WebViewController responseWebViewController = WebViewController();

  List<Widget> pageWidgets = [];
  _buildPageWidgets() {
    if (responseFileHTML != null) {
      responseWebViewController.loadFile(responseFileHTML!.path);
      pageWidgets.add(WebViewWidget(
          controller: responseWebViewController));
    }
    if (questionHTML != null) {
      questionWebViewController.loadHtmlString(questionHTML!);
      pageWidgets.add(WebViewWidget(
          controller: questionWebViewController));
    }

    if (images.isNotEmpty) {
      for (var value in images) {
          pageWidgets.add(Image.memory(value, fit: BoxFit.fill,));
      }
    }
    pp('$mm ... pageWidgets created: ${pageWidgets.length}');
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: OrgLogoWidget(
                branding: branding, height: 20,
              ),
              actions: [
                IconButton(onPressed: (){
                  _shareAIResponse();
                }, icon: const Icon(Icons.send)),
              ],
            ),
            body: ScreenTypeLayout.builder(
              mobile: (_) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        Text(title == null? 'SgelaAI Response Sharing':'$title', style: myTextStyleSmall(context),),
                        Expanded(
                          child: bd.Badge(
                            badgeContent: Text('${pageWidgets.length}'),
                            position: bd.BadgePosition.topEnd(top: 4, end: 12),
                            badgeStyle: const bd.BadgeStyle(
                              padding: EdgeInsets.all(12),
                              badgeColor: Colors.blue,
                            ),
                            child: PageView.builder(
                                itemCount: pageWidgets.length,
                                itemBuilder: (_,index){
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  elevation: 8,
                                  // color: Theme.of(context).primaryColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: pageWidgets.elementAt(index),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SponsoredBy(logoHeight: 20,),
                      ],
                    ),
                  ],
                );
              },
              tablet: (_) {
                return const Stack();
              },
              desktop: (_) {
                return const Stack();
              },
            )));
  }
}
