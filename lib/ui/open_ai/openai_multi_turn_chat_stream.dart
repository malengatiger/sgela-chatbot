import 'package:dart_openai/dart_openai.dart';
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/gemini/widgets/chat_input_box.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/ui/chat/latex_math_viewer.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/misc/sponsored_by.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';

import '../../data/organization.dart';
import '../../data/sponsoree.dart';
import '../../util/functions.dart';

class OpenAIMultiTurnStreamChat extends StatefulWidget {
  const OpenAIMultiTurnStreamChat({super.key, this.examLink, this.subject});

  final ExamLink? examLink;
  final Subject? subject;

  @override
  State<OpenAIMultiTurnStreamChat> createState() =>
      OpenAIMultiTurnStreamChatState();
}

class OpenAIMultiTurnStreamChatState extends State<OpenAIMultiTurnStreamChat> {
  static const mm = '🍐🍐🍐🍐 OpenApiMultiTurnStreamChat 🍐';

  final textEditController = TextEditingController();
  bool _busy = false;

  bool get loading => _busy;
  int turnNumber = 0;

  set loading(bool set) => setState(() => _busy = set);
  final List<Content> chats = [];

  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  Sponsoree? sponsoree;
  String? aiResponseText, fingerPrint;
  int? totalTokens, promptTokens, completionTokens;
  LocalDataService localDataService = GetIt.instance<LocalDataService>();
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  Branding? branding;

  @override
  void initState() {
    super.initState();
    _showModels();
    _getPageContents();
    _getData();
  }

  List<ExamPageContent> examPageContents = [];
  ExamPageContent? examPageContent;

  _getPageContents() async {
    if (widget.examLink != null) {
      examPageContents =
          await localDataService.getExamPageContents(widget.examLink!.id!);
      if (examPageContents.isEmpty) {
        examPageContents =
            await firestoreService.getExamPageContents(widget.examLink!.id!);
      }
    }
    pp('$mm ... ${examPageContents.length} examPageContents found');
  }

  _getData() async {
    pp('$mm ..................... getting data ...');
    setState(() {
      _busy = true;
    });
    try {
      sponsoree = prefs.getSponsoree();
      organization = prefs.getOrganization();
      branding = prefs.getBrand();
      _startOpenAITextChat();
      List<OpenAIModelModel> models = await OpenAI.instance.model.list();
      for (var model in models) {
        pp('$mm OpenAI model: ${model.id} 🍎🍎ownedBy: ${model.ownedBy}');
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  _showModels() async {
    pp('$mm ... show all the AI models available');
  }

  _getFormattingPrompt() {
    var sb = StringBuffer();
    sb.write(
        'Format the following text and improve the look and readability of the output text ');
    if (examPageContent != null) {
      searchedText = '${sb.toString()}\n${examPageContent!.text!}';
      List<Parts> partsContext = [];
      if (turnNumber == 0) {
        partsContext = getMultiTurnContext();
      }
      partsContext.add(Parts(text: searchedText));
      chats.add(Content(role: 'user', parts: partsContext));
      textEditController.clear();
      loading = true;
      // _startAndListenToChatStream();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you', context: context);
    }
  }

  void _handleInputText() {
    if (textEditController.text.isNotEmpty) {
      searchedText = textEditController.text;
      List<Parts> partsContext = [];
      if (turnNumber == 0) {
        partsContext = getMultiTurnContext();
      }
      partsContext.add(Parts(text: searchedText));
      chats.add(Content(role: 'user', parts: partsContext));
      textEditController.clear();
      loading = true;
      _startOpenAITextChat();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you', context: context);
    }
  }

  late String searchedText;

  void _startOpenAITextChat() async {
    pp("$mm ...._startOpenAIStream .....");
    final systemMessage = _buildOpenAISystemMessage();
    final userMessage = _buildOpenAIUserMessage();
    //
    final chatCompletion = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      messages: [
        systemMessage,
        userMessage,
      ],
      seed: 313,
      n: 2,
    );

    pp("$mm ...._startOpenAIStream: 💜💜 chatCompletion created, response from OpenAPI...");
    if (chatCompletion.haveChoices) {
      aiResponseText =
          chatCompletion.choices.first.message.content?.first.text;
      pp('$mm ... 🥦🥦🥦completion.choices.first.finishReason: 🍎🍎 ${chatCompletion.choices.first.finishReason}');
      pp(aiResponseText);
      if (chatCompletion.choices.first.finishReason == 'stop') {
        pp('$mm ...🥦🥦🥦 💛everything is OK, Boss!!, 💛 SgelaAI has responded with answers ...');
        _showMarkdown = true;
      } else {
        if (mounted) {
          showErrorDialog(context,
              'SgelaAI could not help you at this time. Please try again');
        }
      }
    }
  }

  TextEditingController textEditingController = TextEditingController();
  bool _showMarkdown = false;

  OpenAIChatCompletionChoiceMessageModel _buildOpenAIUserMessage() {
    OpenAIChatCompletionChoiceMessageContentItemModel? subjectModel;
    if (widget.subject != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "I would like to talk about ${widget.subject!.title} today",
      );
    } else if (widget.examLink != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "I would like to talk about ${widget.examLink!.subject!.title} today",
      );
    } else {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "Hi SgelaAI",
      );
    }

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [subjectModel],
      role: OpenAIChatMessageRole.user,
    );
    return userMessage;
  }

  OpenAIChatCompletionChoiceMessageModel _buildOpenAISystemMessage() {
    OpenAIChatCompletionChoiceMessageContentItemModel? subjectModel;
    if (widget.subject != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "This session relates to this subject: ${widget.subject!.title}",
      );
    }
    if (widget.examLink != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "This session relates to this subject: ${widget.examLink!.subject!.title}",
      );
    }
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "Your name is SgelaAI and you are a super tutor and educational assistant.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You answer all the questions or solve all the problems you find in the text.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You think step by step for each question or problem",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You use paragraphs, spacing or headings to separate your responses.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You suggest the ways that the reader can improve their mastery of the subject.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "Return any response you make as Markdown. When working with mathematics "
          "or physics equations, return as LaTex",
        ),
      ],
      role: OpenAIChatMessageRole.assistant,
    );
    if (subjectModel != null) {
      systemMessage.content?.add(subjectModel);
    }
    return systemMessage;
  }

  Widget chatItem(BuildContext context, int index) {
    final Content content = chats[index];
    var text = content.parts?.lastOrNull?.text ??
        'Sgela cannot help with your request. Try changing it ...';
    text = modifyString(text);
    bool isLatex = false;
    isLatex = isValidLaTeXString(text);
    String role = 'You';
    if (content.role == 'model') {
      role = 'SgelaAI';
    }

    if (isLatex) {
      return Card(
        elevation: 0,
        color: role == 'SgelaAI' ? Colors.blue.shade800 : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role),
              LaTexViewer(
                text: text,
                showHeader: false,
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 0,
      color:
          content.role == 'model' ? Colors.blue.shade800 : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            Markdown(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                data: content.parts?.lastOrNull?.text ??
                    'Sgela cannot help with your request. Try changing it ...'),
          ],
        ),
      ),
    );
  }

  String modifyString(String input) {
    return input.replaceAll('**', '\n');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Chat with ',
              style: myTextStyleSmall(context),
            ),
            gapW8,
            Text(
              'SgelaAI',
              style: myTextStyle(
                  context, Theme.of(context).primaryColor, 24, FontWeight.w900),
            ),
          ],
        ),
        actions: [
          if (loading)
            const BusyIndicator(
              showTimerOnly: true,
            ),
          IconButton(
              onPressed: () {
                pp('$mm ... do the Share thing ...');
              },
              icon: Icon(Icons.share, color: Theme.of(context).primaryColor)),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: Stack(
          children: [
            Column(
              children: [
                const SponsoredBy(),
                Expanded(
                    child: chats.isNotEmpty
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              reverse: true,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  itemBuilder: chatItem,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: chats.length,
                                  reverse: false,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Text('Say something to SgelaAI'))),
                ChatInputBox(
                  controller: textEditController,
                  onSend: () {
                    _handleInputText();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    ));
  }
}
