
import 'package:edu_chatbot/main.dart';
import 'package:sgela_shared_widgets/widgets/org_logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/sgela_util/environment.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

class GenerativeChatScreen extends StatefulWidget {
  const GenerativeChatScreen({super.key,  this.examLink, this.examPageContents});

  final ExamLink? examLink;
  final List<ExamPageContent>? examPageContents;

  @override
  State<GenerativeChatScreen> createState() => _GenerativeChatScreenState();
}

class _GenerativeChatScreenState extends State<GenerativeChatScreen> {

  Prefs prefs = GetIt.instance<Prefs>();
  Branding? branding;
  String? examText;
  static const mm = '🍎🍎🍎🍎GenerativeChatScreen 🍎🍎';

  @override
  void initState() {
    super.initState();
    _getData();
  }

  _getData() {
    branding = prefs.getBrand();
    var sb = StringBuffer();
    if ((widget.examPageContents != null)) {
      widget.examPageContents?.forEach((page) {
        if (page.text != null) {
          sb.write(page.text!);
        }
      });
    }
    examText = sb.toString();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: OrgLogoWidget(branding: branding, height: 24,),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Card(
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: GenerativeChatWidget(),
            )),
      ),
    );
  }
}

class GenerativeChatWidget extends StatefulWidget {
  const GenerativeChatWidget({super.key});

  @override
  State<GenerativeChatWidget> createState() => _GenerativeChatWidgetState();
}

class _GenerativeChatWidgetState extends State<GenerativeChatWidget> {
  late final ai.GenerativeModel _model;
  late final ai.ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  final _apiKey = ChatbotEnvironment.getGeminiAPIKey();

  @override
  void initState() {
    super.initState();
    _setModel();
  }

  _setModel() async {

    _model = ai.GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();

  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });
    List<ai.Part> parts = [];
    ai.Content content = ai.Content.model(parts);

    ai.GenerationConfig config = ai.GenerationConfig(temperature: 0.0, maxOutputTokens: 1000);

    try {
      var response = await _chat.sendMessage(
        ai.Content.text(message),
      );
      var text = response.text;

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(

              controller: _scrollController,
              itemBuilder: (context, idx) {
                var content = _chat.history.toList()[idx];
                var text = content.parts
                    .whereType<ai.TextPart>()
                    .map<String>((e) => e.text)
                    .join('');
                return GenerativeMessageWidget(
                  text: text,
                  isFromUser: content.role == 'user',
                );
              },
              itemCount: _chat.history.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: (String value) {
                      _sendChatMessage(value);
                    },
                  ),
                ),
                const SizedBox.square(
                  dimension: 15,
                ),
                if (!_loading)
                  IconButton(
                    onPressed: () async {
                      dismissKeyboard(context);
                      _sendChatMessage(_textController.text);
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GenerativeMessageWidget extends StatelessWidget {
  final String text;
  final bool isFromUser;

  const GenerativeMessageWidget({
    super.key,
    required this.text,
    required this.isFromUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: isFromUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.blue,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 8,
              child: MarkdownBody(
                selectable: true,
                data: text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
