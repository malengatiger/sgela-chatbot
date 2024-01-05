import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownWidget extends StatelessWidget {
  const MarkdownWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: SizedBox(
        height: 500, width:400,
        child: Markdown(
          data: text,
          selectable: true,
          controller: ScrollController(),
        ),
      ),
    );
  }
}