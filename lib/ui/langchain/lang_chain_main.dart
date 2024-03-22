
import 'package:edu_chatbot/ui/gemini/widgets/chat_input_box.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/embeddings/langchain_service_impl.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_shared_widgets/util/dialogs.dart';
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';


class LangChainMain extends StatefulWidget {
  const LangChainMain({super.key, required this.examLink});

  final ExamLink examLink;
  @override
  LangChainMainState createState() => LangChainMainState();
}

class LangChainMainState extends State<LangChainMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  LangChainServiceImpl langChainService = GetIt.instance<LangChainServiceImpl>();

  static const mm = '🔵🔵🔵🔵 LangChainMain  🔵🔵';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  bool _busy = false;

  _getData() async {
    pp('$mm ... getting data ...');
    setState(() {
      _busy = false;
    });
    try {
      await langChainService.buildEmbeddings(widget.examLink);
      // _sendQuery();
    } catch (e,s) {
      pp('$mm $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  TextEditingController textController = TextEditingController(text: 'List all the questions in the document');
  String? responseText;
  _sendQuery() async {
    pp('$mm ... send query ........... exam${widget.examLink.id} ');
    var indexName = 'exam${widget.examLink.id}';
    if (textController.text.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      responseText = await langChainService.queryPineConeVectorStore(
              indexName, textController.text);
    } catch (e,s) {
      pp('$mm $e $s');
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
                return   Stack(
                  children: [
                    Column(
                      children: [
                        const Expanded(child: Card(
                          child: SizedBox(),
                        )),
                        ChatInputBox(controller: textController, onSend: (){
                          _sendQuery();
                        },),
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
