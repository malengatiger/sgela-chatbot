import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

import '../../local_util/functions.dart';
import '../chat/sgela_markdown_widget.dart';

class GenericImageResponseViewer extends StatefulWidget {
  const GenericImageResponseViewer(
      {super.key,
      required this.text,
      required this.isLaTex,
      required this.file});

  final String text;
  final bool isLaTex;
  final File file;

  @override
  State<GenericImageResponseViewer> createState() =>
      _GenericImageResponseViewerState();
}

class _GenericImageResponseViewerState
    extends State<GenericImageResponseViewer> {
  bool showThumbnail = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Result from Image', style: myTextStyleSmall(context)),
        actions: [
          showThumbnail
              ? gapW8
              : IconButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        showThumbnail = !showThumbnail;
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt))
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  gapH16,
                  Text(
                    'SgelaAI Image Response',
                    style: myTextStyle(context, Theme.of(context).primaryColor,
                        18, FontWeight.w900),
                  ),
                  gapH32,
                  widget.isLaTex
                      ? SingleChildScrollView(
                        child: TeXView(
                          renderingEngine:
                              const TeXViewRenderingEngine.katex(),
                          child: TeXViewColumn(
                            children: [
                              TeXViewDocument(widget.text),
                            ],
                          ),
                        ),
                      )
                      : SgelaMarkdownWidget(text: widget.text),
                ],
              ),
            )),
          ),
          showThumbnail
              ? Positioned(
                  bottom: 24,
                  left: 28,
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          showThumbnail = false;
                        });
                      }
                    },
                    child: Card(
                        elevation: 16,
                        child: Image.file(widget.file,
                            height: 160, width: 160, fit: BoxFit.cover)),
                  ),
                )
              : gapW8,
        ],
      ),
    ));
  }
}
