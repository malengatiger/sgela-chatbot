import 'package:edu_chatbot/ui/gemini/widgets/chat_input_box.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';


class GeminiTextChatWidget extends StatefulWidget {
  const GeminiTextChatWidget({super.key, this.examLink, this.examPageContents});

  final ExamLink? examLink;
  final List<ExamPageContent>? examPageContents;

  @override
  State<GeminiTextChatWidget> createState() => _GeminiTextChatWidgetState();
}

class _GeminiTextChatWidgetState extends State<GeminiTextChatWidget> {
  final controller = TextEditingController();
  final gemini = GetIt.instance<Gemini>();
  bool _loading = false;
  static const mm = '🍐🍐🍐🍐 GeminiTextChatWidget 🍎🍎';

  bool get loading => _loading;
  Branding? branding;

  set loading(bool set) => setState(() => _loading = set);
  final List<Content> chats = [];
  Prefs prefs = GetIt.instance<Prefs>();

  @override
  void initState() {
    super.initState();
    _getChatContext();
  }

  List<Content> _getChatContext() {
    setState(() {
      _loading = true;
    });
    branding = prefs.getBrand();
    chats.add(Content(parts: [
      Parts(
          text:
              'I am a super tutor and assistant for high school and college freshman students and teachers ')
    ], role: 'model'));

    chats.add(Content(parts: [
      Parts(
          text:
              'I need your help to answer exam and test questions for a specific subject')
    ], role: 'user'));

    chats.add(Content(parts: [
      Parts(text: 'I answer all questions and problems I find in your text')
    ], role: 'model'));

    chats.add(Content(
        parts: [Parts(text: 'I solve problems step by step')], role: 'model'));

    chats.add(Content(
        parts: [Parts(text: 'I return my responses in markdown format')],
        role: 'model'));

    chats.add(Content(parts: [
      Parts(
          text:
              'Each response to a question will be in its own paragraph and a heading where suitable')
    ], role: 'model'));

    chats.add(Content(parts: [
      Parts(text: 'I may need to ask you follow up questions about the exam')
    ], role: 'user'));

    chats.add(Content(parts: [
      Parts(text: 'Tell me the subject and attach the exam questions')
    ], role: 'model'));

    if (widget.examLink != null) {
      chats.add(Content(parts: [
        Parts(
            text:
                'The subject is ${widget.examLink!.subject!.title}, the questions follow')
      ], role: 'user'));
    }

    var sb = StringBuffer();

    if (widget.examPageContents != null) {
      pp('$mm ... setting chat context for exam page contents: ${widget.examPageContents!.length}');
      for (var element in widget.examPageContents!) {
        if (element.text != null) {
          sb.write('${element.text}\n\n');
        }
      }
    }

    chats.add(Content(parts: [Parts(text: sb.toString())], role: 'user'));
    pp('$mm ... chat context has been set. chats: ${chats.length}');
    //
    setState(() {
      _loading = false;
    });
    return chats;
  }

  Widget _buildChatItem(BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: OrgLogoWidget(
          branding: branding,
        ),
      ),
      body: ScreenTypeLayout.builder(
        mobile: (_) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                        child: chats.isNotEmpty
                            ? Align(
                                alignment: Alignment.bottomCenter,
                                child: SingleChildScrollView(
                                  reverse: true,
                                  child: ListView.builder(
                                    itemBuilder: _buildChatItem,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: chats.length,
                                    reverse: false,
                                  ),
                                ),
                              )
                            : const Center(child: Text('Search something!'))),
                    if (loading) const CircularProgressIndicator(),
                    ChatInputBox(
                      controller: controller,
                      onSend: () {
                        if (controller.text.isNotEmpty) {
                          final searchedText = controller.text;
                          chats.add(Content(
                              role: 'user',
                              parts: [Parts(text: searchedText)]));
                          controller.clear();
                          loading = true;

                          gemini.chat(chats).then((value) {
                            chats.add(Content(
                                role: 'model',
                                parts: [Parts(text: value?.output)]));
                            loading = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
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
      ),
    ));
  }
}
