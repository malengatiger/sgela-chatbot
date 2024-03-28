import 'package:edu_chatbot/local_util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/embeddings/langchain_service_impl.dart';
import 'package:sgela_services/sgela_util/functions.dart' as fun;
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';

import '../gemini/widgets/chat_input_box.dart';

class LangChainMain extends StatefulWidget {
  const LangChainMain({super.key, required this.examLink});

  final ExamLink examLink;

  @override
  LangChainMainState createState() => LangChainMainState();
}

class LangChainMainState extends State<LangChainMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  LangChainServiceImpl langChainService =
  GetIt.instance<LangChainServiceImpl>();

  static const mm = '🔵🔵🔵🔵 LangChainMain  🔵🔵';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  bool _busy = false;

  _getData() async {
    fun.pp('$mm ... getting data ...');
    setState(() {
      _busy = false;
    });
    try {
      var ok = await langChainService.buildEmbeddings(
          widget.examLink);
      if (ok) {
      _sendQuery();
      }
    } catch (e, s) {
      fun.pp('$mm $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  TextEditingController textController =
  TextEditingController(text: 'List all the questions in the document');
  String? responseText;

  _sendQuery() async {
    fun.pp('$mm ... send query ........... exam${widget.examLink.id} ');
    var indexName = 'exam${widget.examLink.id}';
    if (textController.text.isEmpty) {
      showToast(
          backgroundColor: Colors.red.shade400,
          textStyle: const TextStyle(color: Colors.white),
          padding: 24,
          message: 'Enter your query',
          context: context);
      return;
    }
    setState(() {
      _busy = true;
    });

    try {
      responseText = await langChainService.queryPineConeVectorStore(
          indexName, textController.text);
      fun.pp('$mm response from langChain: $responseText');
    } catch (e, s) {
      fun.pp('$mm $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('LangChain'),
            ),
            body: ScreenTypeLayout.builder(
              mobile: (_) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                            child: Card(
                                child: responseText == null ? gapH16 : SizedBox(
                                  child: Markdown(data: responseText!,

                                  ),
                                ),
                            )),
                        ChatInputBox(
                          controller: textController,
                          onSend: () {
                            _sendQuery();
                          },
                        ),
                        const SponsoredBy(),
                      ],
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
            )));
  }
}
