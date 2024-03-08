import 'package:badges/badges.dart' as bd;
import 'package:dart_openai/dart_openai.dart';
import 'package:dart_openai/src/instance/chat/chat.dart';
import 'package:edu_chatbot/ui/chat/latex_math_viewer.dart';
import 'package:edu_chatbot/ui/gemini/widgets/chat_input_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/exam_page_content.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/data/subject.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/services/local_data_service.dart';
import 'package:sgela_services/sgela_util/db_methods.dart';
import 'package:sgela_services/sgela_util/dio_util.dart';
import 'package:sgela_services/sgela_util/environment.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/sponsored_by.dart';

import '../../local_util/functions.dart';

class ClaudeAITextChatWidget extends StatefulWidget {
  const ClaudeAITextChatWidget(
      {super.key, this.examLink, this.examPageContents, this.subject});

  final ExamLink? examLink;
  final List<ExamPageContent>? examPageContents;
  final Subject? subject;

  @override
  State<ClaudeAITextChatWidget> createState() => ClaudeAITextChatWidgetState();
}

class ClaudeAITextChatWidgetState extends State<ClaudeAITextChatWidget> {
  static const mm = '🍐🍐🍐🍐 ClaudeAITextChatWidget 🍐';

  TextEditingController textEditController = TextEditingController();
  bool _busy = false;

  int turnNumber = 0;

  set loading(bool set) => setState(() => _busy = set);
  final List<Content> chats = [];

  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  Sponsoree? sponsoree;
  String? fingerPrint;
  int? totalTokens, promptTokens, completionTokens;
  LocalDataService localDataService = GetIt.instance<LocalDataService>();
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  Branding? branding;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  String inputText = 'Hello!';

  _getPageContents() async {
    var sb = StringBuffer();
    if (widget.examPageContents != null) {
      pp('$mm ... ${widget.examPageContents!.length} examPageContents found');
      for (var page in widget.examPageContents!) {
        if (page.text != null) {
          sb.write(page.text!);
        }
      }
    }
    if (sb.isNotEmpty) {
      inputText = _replaceKeywordsWithBlanks(sb.toString());
      inputText =
          'Find the questions or problems in the text below and respond with the solutions in markdown format.\n'
          'Show solution steps where necessary.\n The text: $inputText';
      textEditController = TextEditingController(text: inputText);
    }
    if (widget.examLink != null) {
      inputText =
          'Help me with this subject: ${widget.examLink!.subject!.title!}';
    }
    if (widget.subject != null) {
      inputText = 'Help me with this subject: ${widget.subject!.title!}';
    }

    pp('$mm ... examPageContents: inputText: ${inputText.length} bytes');
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
      if (widget.subject != null) {
        inputText = widget.subject!.title!;
      }
      await _getPageContents();
      await Future.delayed(const Duration(milliseconds: 200));
      _startOpenAITextChat(inputText, true);
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
      _busy = true;
      _startOpenAITextChat(textEditController.text, false);
      textEditController.clear();
    } else {
      showToast(
          message: 'Say something, I did not quite hear you', context: context);
    }
  }

  late String searchedText;
  late OpenAIChat openAIChat = OpenAI.instance.chat;
  late OpenAIChatCompletionModel completionModel;
  List<OpenAIChatCompletionChoiceMessageModel> messages = [];

  void _arrangeMessages() {
    List<OpenAIChatCompletionChoiceMessageModel> arrangedMessages = [];
    for (var msg in messages) {
      if (msg.role.name != 'system') {
        arrangedMessages.add(msg);
      }
    }
    //arrangedMessages.add(_buildOpenAISystemMessage());
    int index = arrangedMessages.length ~/ 2;
    pp("$mm ....arrangedMessages: .....index: $index length: ${arrangedMessages.length}");

    messages.clear();
    messages.addAll(arrangedMessages);
    messages.insert(index, _buildOpenAISystemMessage());
  }

  void _startOpenAITextChat(String text, bool isFirstTime) async {
    pp("$mm ...._startOpenAITextChat ..... isFirstTime: $isFirstTime text: $text");

    _prepareMessages(isFirstTime, text);
    List<Parts> partsContext = [];

    try {
      setState(() {
        _busy = true;
      });
      // if (isFirstTime) {
        completionModel = await openAIChat.create(
            temperature: 0.0,
            model: ChatbotEnvironment.getOpenAIModel(),
            messages: messages);
      // }
      //
      partsContext.add(Parts(
          text: completionModel.choices.first.message.content?.first.text));
      chats.add(Content(role: 'model', parts: partsContext));
      if (completionModel.choices.first.finishReason == 'stop') {
        pp('$mm ...🥦🥦🥦 💛everything is OK, Boss!!, 💛 OpenAI has responded with answers ...');
      } else {
        if (mounted) {
          showErrorDialog(context,
              'SgelaAI could not help you at this time. Please try again with Gemini model');
        }
      }
      _print();
      _addTokensUsed();
    } catch (e, s) {
      pp('$mm $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }

    setState(() {
      _busy = false;
    });
  }

  DioUtil dioUtil = GetIt.instance<DioUtil>();

  // Future _countTokens(
  //     {required String prompt,
  //       required List<String> systemStrings}) async {
  //
  //   var res = await dioUtil.countGeminiTokens(
  //       prompt: prompt, files: [], model: 'gpt-3.5-turbo-16k-0613');
  //   pp('$mm token response: $res ... will write TokensUsed');
  // }

  List<String> systemStrings = [];

  void _prepareMessages(bool isFirstTime, String text) {
    if (isFirstTime) {
      messages
          .add(_buildFirstTimeOpenAIUserMessage(text.isEmpty ? 'Hi!' : text));
      messages.add(_buildOpenAISystemMessage());
    } else {
      messages.add(_buildOpenAIUserMessage());
      _arrangeMessages();
    }
  }

  void _print() {
    pp('$mm ... 🥦🥦🥦chat stream, finishReason: ${completionModel.choices.first.finishReason}');
    // pp('$mm ... 🥦🥦🥦chat stream, text: ${completionModel.choices.first.message.content?.first.text}');
    pp('$mm ... 🥦🥦🥦chat stream, 🍎🍎🍎 usage: ${completionModel.usage.toMap()} 🍎🍎🍎');
  }

  _addTokensUsed() {
    promptTokens = completionModel.usage.promptTokens;
    completionTokens = completionModel.usage.completionTokens;
    totalTokens = completionModel.usage.totalTokens;
    DBMethods.addTokensUsed(totalTokens!, sponsoree!, modelOpenAI);
  }

  OpenAIChatCompletionChoiceMessageModel _buildFirstTimeOpenAIUserMessage(
      String? text) {
    OpenAIChatCompletionChoiceMessageContentItemModel? subjectModel;
    OpenAIChatCompletionChoiceMessageContentItemModel? userModel;

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
    if (text != null) {
      userModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(text);
    } else {
      userModel =
          OpenAIChatCompletionChoiceMessageContentItemModel.text('Hello!');
    }

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [subjectModel, userModel],
      role: OpenAIChatMessageRole.user,
    );
    return userMessage;
  }

  OpenAIChatCompletionChoiceMessageModel _buildOpenAIUserMessage() {
    var text = 'Hello!';
    if (textEditController.text.isNotEmpty) {
      text = textEditController.text;
    }
    OpenAIChatCompletionChoiceMessageContentItemModel subjectModel =
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
      text,
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
    } else if (widget.examLink != null) {
      subjectModel = OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "This session relates to this subject: ${widget.examLink!.subject!.title}",
      );
    }
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "My name is SgelaAI and I am a super tutor and educational assistant.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "I answer all the questions or solve all the problems you find in the text.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "I think step by step for each question or problem",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "I use paragraphs, spacing or headings to separate your responses.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "I suggest the ways that the reader can improve their mastery of the subject.",
        ),
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "I return any response you make as Markdown. When working with mathematics "
          "or physics equations, return as LaTex",
        ),
      ],
      role: OpenAIChatMessageRole.system,
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
              LaTexCard(
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

  String _replaceKeywordsWithBlanks(String text) {
    String modifiedText = text
        .replaceAll("Copyright reserved", "")
        .replaceAll("Please turn over", "");
    return modifiedText;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _busy
                ? gapW4
                : Text(
                    'Chat with ',
                    style: myTextStyleSmall(context),
                  ),
            gapW8,
            _busy
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
          if (_busy)
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
                            child: bd.Badge(
                              badgeContent: Text('${chats.length}'),
                              position:
                                  bd.BadgePosition.topEnd(top: -16, end: -8),
                              badgeStyle: const bd.BadgeStyle(
                                padding: EdgeInsets.all(12.0),
                              ),
                              onTap: () {
                                pp('$mm badge tapped, scroll up or down');
                              },
                              child: SingleChildScrollView(
                                reverse: true,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: chats.length,
                                    reverse: false,
                                    itemBuilder: (_, index) {
                                      return chatItem(context, index);
                                    },
                                  ),
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
            ),
            _busy
                ? const Positioned(
                    bottom: 24,
                    left: 24,
                    child: SizedBox(
                        width: 120,
                        height: 100,
                        child: Center(
                          child: BusyIndicator(
                            showTimerOnly: true,
                          ),
                        )))
                : gapW4,
          ],
        ),
      ),
    ));
  }
}
