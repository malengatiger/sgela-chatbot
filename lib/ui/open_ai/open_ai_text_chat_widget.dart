import 'package:dart_openai/dart_openai.dart';
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
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

class OpenAITextChatWidget extends StatefulWidget {
  const OpenAITextChatWidget({super.key, this.examLink, this.examPageContents});

  final ExamLink? examLink;
  final List<ExamPageContent>? examPageContents;

  @override
  State<OpenAITextChatWidget> createState() => OpenAITextChatWidgetState();
}

class OpenAITextChatWidgetState extends State<OpenAITextChatWidget> {
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
    //
    try {
      sponsoree = prefs.getSponsoree();
      organization = prefs.getOrganization();
      branding = prefs.getBrand();
      await _getPageContents();

      List<OpenAIModelModel> models = await OpenAI.instance.model.list();
      for (var model in models) {
        pp('$mm OpenAI model: ${model.id} 🍎🍎ownedBy: ${model.ownedBy}');
      }
      _startOpenAITextChat('', true);
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

  void _handleInputText() {
    pp('$mm ....... handling input: ${textEditController.text}');
    if (textEditController.text.isNotEmpty) {
      searchedText = textEditController.text;
      List<Parts> partsContext = [];
      if (turnNumber == 0) {
        partsContext = getMultiTurnContext();
      }
      partsContext.add(Parts(text: searchedText));
      chats.add(Content(role: 'user', parts: partsContext));
      loading = true;
      _startOpenAITextChat(textEditController.text, false);
      textEditController.clear();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you', context: context);
    }
  }

  late String searchedText;
  late OpenAIChatCompletionModel completionModel;

  void _startOpenAITextChat(String text, bool isFirstTime) async {
    pp("$mm ...._startOpenAIStream .....");
    final systemMessage = _buildOpenAISystemMessage();
    OpenAIChatCompletionChoiceMessageModel userMessage;
    if (isFirstTime) {
      userMessage = _buildFirstTimeOpenAIUserMessage();
    } else {
      userMessage = _buildOpenAIUserMessage();
    }
    //
    pp('$mm ... chat.endpoint: ${OpenAI.instance.chat.endpoint}');
    var completionModel = await OpenAI.instance.chat.create(
        temperature: 0.0,
        model: 'gpt-3.5-turbo',
        messages: [systemMessage, userMessage]);

    pp('$mm ... 🥦🥦🥦chat stream, finishReason: ${completionModel.choices.first.finishReason}');
    pp('$mm ... 🥦🥦🥦chat stream, text: ${completionModel.choices.first.message.content?.first.text}');

    List<Parts> partsContext = [];
    aiResponseText = completionModel.choices.first.message.content?.first.text;
    partsContext.add(Parts(text: aiResponseText));
    chats.add(Content(role: 'model', parts: partsContext));
    pp(aiResponseText);
    if (completionModel.choices.first.finishReason == 'stop') {
      pp('$mm ...🥦🥦🥦 💛everything is OK, Boss!!, 💛 SgelaAI has responded with answers ...');
      _showMarkdown = true;
    } else {
      if (mounted) {
        showErrorDialog(context,
            'SgelaAI could not help you at this time. Please try again');
      }
    }

    setState(() {
      loading = false;
    });
  }

  // TextEditingController textEditingController = TextEditingController();
  bool _showMarkdown = false;

  OpenAIChatCompletionChoiceMessageModel _buildFirstTimeOpenAIUserMessage() {
    OpenAIChatCompletionChoiceMessageContentItemModel? subjectModel;
    if (widget.examLink != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "I would like to talk about ${widget.examLink!.subject!.title} today",
      );
    } else if (widget.examLink != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "I would like to talk about ${widget.examLink!.subject!.title} today",
      );
    } else {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "I need your help to study all sorts of subjects and prepare for examinations",
      );
    }

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [subjectModel],
      role: OpenAIChatMessageRole.user,
    );
    return userMessage;
  }

  OpenAIChatCompletionChoiceMessageModel _buildOpenAIUserMessage() {
    OpenAIChatCompletionChoiceMessageContentItemModel subjectModel =
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
      textEditController.text,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [subjectModel],
      role: OpenAIChatMessageRole.user,
    );
    return userMessage;
  }

  OpenAIChatCompletionChoiceMessageModel _buildOpenAISystemMessage() {
    OpenAIChatCompletionChoiceMessageContentItemModel? subjectModel;
    if (widget.examLink != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "This session relates to this subject: ${widget.examLink!.subject!.title}",
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
    // pp('$mm ... chatItem: content  $content');
    var text = content.parts?.lastOrNull?.text ??
        'Sgela cannot help with your request. Try changing it ...';
    text = modifyString(text);
    bool isLatex = isValidLaTeXString(text);
    String role = 'You';
    if (content.role == 'model' || content.role == 'system') {
      role = 'SgelaAI';
    }
    pp('$mm ... chatItem: role: $role');
    if (isLatex) {
      return Card(
        elevation: 0,
        color: role == 'SgelaAI' ? Colors.teal.shade800 : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: role == 'SgelaAI'
                    ? myTextStyleMediumLarge(context, 20)
                    : myTextStyleMediumLarge(context, 14),
              ),
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
          content.role == 'model' ? Colors.teal.shade800 : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            Card(
              elevation: 8,
              color: content.role == 'model'
                  ? Colors.teal.shade800
                  : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Markdown(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    data: content.parts?.lastOrNull?.text ??
                        'Sgela cannot help with your request. Try changing it ...'),
              ),
            ),
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
            loading
                ? gapW4
                : Text(
                    'Chat with ',
                    style: myTextStyleSmall(context),
                  ),
            gapW8,
            loading
                ? gapW4
                : Text(
                    'SgelaAI',
                    style: myTextStyle(context, Theme.of(context).primaryColor,
                        24, FontWeight.w900),
                  ),
            gapW16,
            Text(
              '(Open AI)',
              style: myTextStyleTiny(context),
            )
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
                Expanded(
                    child: chats.isNotEmpty
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              reverse: true,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: chats.length,
                                  reverse: false,
                                  itemBuilder: (_, index) {
                                    return chatItem(context, index);
                                  },
                                ),
                              ),
                            ),
                          )
                        : const Center(child: Text('Say hello to SgelaAI'))),
                ChatInputBox(
                  controller: textEditController,
                  onSend: () {
                    _handleInputText();
                  },
                ),
                const SponsoredBy(
                  height: 36,
                ),
              ],
            )
          ],
        ),
      ),
    ));
  }
}
