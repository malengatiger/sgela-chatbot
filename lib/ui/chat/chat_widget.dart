import 'package:flutter/material.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:sgela_services/repositories/basic_repository.dart';
import 'package:sgela_services/services/gemini_chat_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import '../../local_util/functions.dart' as fun;
import 'sgela_markdown_widget.dart' as md;

class ChatWidget extends StatefulWidget {
  const ChatWidget(
      {super.key,
      required this.examLink,
      required this.repository,
      required this.chatService,
      required this.subject});

  final ExamLink examLink;
  final BasicRepository repository;
  final GeminiChatService chatService;
  final Subject subject;

  @override
  State<ChatWidget> createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  String responseText = 'The response text will show up right here. ';
  static const mm = '🍎🍎🍎ChatWidget 🍎';
  bool busy = false;
  int chatCount = 0;
  TextEditingController textEditingController = TextEditingController();
  List<String> promptHistory = [];
  String copiedText = '';

  void _handleTextFieldTap() {
    if (textEditingController.selection.isValid) {
      final selectedText = textEditingController.selection
          .textInside(textEditingController.text);
      if (selectedText.isNotEmpty) {
        setState(() {
          copiedText = selectedText;
        });
      }
    }
  }

  bool isMarkDown = false;

  Future<String> _sendChatPrompt() async {
    String prompt = textEditingController.value.text;
    var promptContext = _getPromptContext();
    if (chatCount == 0) {
      prompt = '$promptContext \nSubject: ${widget.subject.title}. $prompt';
    } else {
      prompt = '$promptContext $prompt';
    }
    pp('$mm .............. sending chat prompt: \n$prompt\n');
    StringBuffer sb = StringBuffer();

    setState(() {
      busy = true;
    });
    try {
      var resp = await widget.chatService.sendChatPrompt(prompt);
      pp('$mm ....... chat response: \n$resp\n');
      responseText = resp;
      if (isMarkdownFormats(responseText)) {
        isMarkDown = true;
        pp('$mm ....... isMarkdownFormat: 🍎$isMarkdownFormats 🍎');
      } else {
        isMarkDown = false;
      }
      chatCount++;
      promptHistory.add(resp);
    } catch (e) {
      pp(e);
      if (mounted) {
        fun.showErrorDialog(context, 'Error: $e');
      }
    }
    setState(() {
      busy = false;
    });

    return sb.toString();
  }

  String _getPromptContext() {
    StringBuffer sb = StringBuffer();
    sb.write(
        'My name is SgelaAI and I am a super tutor who knows everything. I am here to help you study for all your high school courses and subjects\n');
    sb.write('I answer questions that relates to the subject provided. \n');
    sb.write('I keep my answers to the high school or college freshman level');
    sb.write(
        'I return all my responses in markdown format. I use headings and paragraphs to enhance readability');
    return sb.toString();
  }

  _showSearchDialog() {

  }

  bool _showsearchInput = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SgelaAI Chat'),
          actions: [
            IconButton(
                onPressed: () {
                  _showsearchInput = true;
                  _showSearchDialog();
                },
                icon: const Icon(Icons.search)),
          ],
        ),
        backgroundColor: Colors.brown[100],
        body: Stack(
          children: [
            Positioned(
              top: 2, left: 8, right: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 16.0,
                   child: Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       crossAxisAlignment: CrossAxisAlignment.center,
                                       children: [
                      SizedBox(width:400,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Search Text Here',
                          ),
                          controller: textEditingController,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: const ButtonStyle(
                          elevation: MaterialStatePropertyAll(8.0),
                        ),
                        onPressed: () {
                          _sendChatPrompt();
                        },
                        icon: const Icon(
                          Icons.send,
                        ),
                        label: const Text('Send to SgelaAI'),
                      ),
                                       ],
                                     ),
                   ),
                ),
              )
            ),
            Positioned(
              top: 148,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: isMarkDown
                    ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: md.SgelaMarkdownWidget(text: responseText),
                    )
                    : Text(
                        '${widget.subject.title}',
                        style: fun.myTextStyle(
                            context, Colors.black, 18, FontWeight.w900),
                      ),
              ),
            ),
            // Positioned(
            //   bottom: 24, left:20,right:20,
            //   child:  SearchInput(textEditingController: textEditingController, onSendTapped: (){
            //   _sendChatPrompt();
            // }),),
          ],
        ),
      ),
    );
  }
}

class SearchInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final Function onSendTapped;

  const SearchInput(
      {super.key,
      required this.textEditingController,
      required this.onSendTapped});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height:140,
      child: Column(mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 140,
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search Text Here',
              ),
              controller: textEditingController,
            ),
          ),
          fun.gapH16,
          ElevatedButton.icon(
            style: const ButtonStyle(
              elevation: MaterialStatePropertyAll(8.0),
            ),
            onPressed: () {
              onSendTapped();
            },
            icon: const Icon(
              Icons.send,
            ),
            label: const Text('Send to SgelaAI'),
          ),
        ],
      ),
    );
  }
}


