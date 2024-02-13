import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SgelaMarkdownWidget extends StatelessWidget {
  const SgelaMarkdownWidget({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        elevation: 8,
        child: SizedBox(
          height: 600, width:420,
          child: Markdown(
            data: text,
            selectable: true,
            controller: ScrollController(),
            onTapText: (){
              pp('Markdown: onTap .........................');
            },
          ),
        ),
      ),
    );
  }
}