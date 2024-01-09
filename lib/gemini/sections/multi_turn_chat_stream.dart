import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/gemini/widgets/chat_input_box.dart';
import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../util/functions.dart';

class MultiTurnStreamChat extends StatefulWidget {
  const MultiTurnStreamChat({super.key, required this.gemini, required this.examLink});

  final Gemini gemini;
  final ExamLink examLink;

  @override
  State<MultiTurnStreamChat> createState() => MultiTurnStreamChatState();
}

class MultiTurnStreamChatState extends State<MultiTurnStreamChat> {
  static const mm = '🍐🍐🍐🍐 SectionStreamChat 🍐';

  final controller = TextEditingController();
  bool _busy = false;

  bool get loading => _busy;
  int turnNumber = 0;

  set loading(bool set) => setState(() => _busy = set);
  final List<Content> chats = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
             Text('Chat with ', style: myTextStyleSmall(context),),
            gapW8,
            Text(
              'SgelaAI',
              style: myTextStyle(
                  context, Theme.of(context).primaryColor,
                  24, FontWeight.w900),
            ),
          ],
        ),
        actions: [
          if (loading)  Row(
            children: [
              const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(
                strokeWidth: 6, backgroundColor: Colors.red,
              )),
              gapW32,
              IconButton(onPressed: (){}, icon: Icon(Icons.share, color: Theme.of(context).primaryColor)),
            ],
          )
        ],
      ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                      child: chats.isNotEmpty
                          ? Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          reverse: true,
                          child: ListView.builder(
                            itemBuilder: chatItem,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: chats.length,
                            reverse: false,
                          ),
                        ),
                      )
                          : const Center(child: Text('Search something!'))),
                  // if (loading) const BusyIndicator(
                  //   showClock: false,
                  //   caption: 'Just a second, please!'
                  // ),
                  ChatInputBox(
                    controller: controller,
                    onSend: () {
                      if (controller.text.isNotEmpty) {
                        final searchedText = turnNumber == 0
                            ? '${getPromptContext()} \n${controller.text}'
                            : controller.text;
                        List<Parts> partsContext = [];
                        if (turnNumber == 0) {
                          partsContext = getMultiTurnContext();
                        }
                        partsContext.add(Parts(text: searchedText));
                        chats.add(
                            Content(role: 'user', parts: partsContext));
                        controller.clear();
                        loading = true;
                        _startAndListenToChatStream();
                      }
                    },
                  ),
                ],
              )
            ],
          ),
    ));
  }

  void _startAndListenToChatStream() {
    pp('$mm _startAndListenToChatStream ......  ');
    widget.gemini.streamChat(chats).listen((candidates) {
      pp("$mm gemini.streamChat fired!: chats: ${chats.length} "
          "------------------------------->>>");
      pp('$mm ${candidates.output}');
      turnNumber++;
      setState(() {
        if (chats.isNotEmpty && chats.last.role == candidates.content?.role) {
          chats.last.parts!.last.text =
              '${chats.last.parts!.last.text}${candidates.output}';
        } else {
          chats.add(
              Content(role: 'model', parts: [Parts(text: candidates.output)]));
          pp('$mm added to chats, now we have ${chats.length} chats. turnNumber: $turnNumber');
        }
      });
    });
  }

  Widget chatItem(BuildContext context, int index) {
    final Content content = chats[index];

    return Card(
      elevation: 0,
      color:
          content.role == 'model' ? Colors.blue.shade800 : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.role ?? 'role'),
            Markdown(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                data:
                    content.parts?.lastOrNull?.text ?? 'cannot generate data!'),
          ],
        ),
      ),
    );
  }
}
