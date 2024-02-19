import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/sponsoree.dart';

class LocalPDFViewerWidget extends StatefulWidget {
  final File pdfFile;

  const LocalPDFViewerWidget({super.key, required this.pdfFile});

  @override
  State<LocalPDFViewerWidget> createState() => _LocalPDFViewerWidgetState();
}

class _LocalPDFViewerWidgetState extends State<LocalPDFViewerWidget> {
  late WebViewController webController;

  Sponsoree? sponsoree;
  Organization? organization;
  Branding? branding;
  Prefs prefs = GetIt.instance<Prefs>();
  @override
  void initState() {
    super.initState();
    _init();
    _setController();
  }
  _init()  {
    sponsoree = prefs.getSponsoree();
    organization = prefs.getOrganization();
    branding = prefs.getBrand();
  }
  _setController() async {
    var bytes = await widget.pdfFile.readAsBytes();
    final String base64 = base64Encode(bytes);
    final String dataUri = 'data:application/pdf;base64,$base64';
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(dataUri));
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Title'),
            ),
            body: ScreenTypeLayout.builder(
              mobile: (_) {
                return  Stack(
                  children: [
                    WebViewWidget(controller: webController),
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

