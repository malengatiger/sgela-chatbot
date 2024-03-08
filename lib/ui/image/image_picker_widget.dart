import 'dart:io';

import 'package:edu_chatbot/ui/image/generic_image_response_viewer.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/services/gemini_chat_service.dart';
import 'package:sgela_services/sgela_util/environment.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';

import '../../local_util/functions.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget(
      {super.key, required this.chatService, this.examLink});

  final GeminiChatService chatService;
  final ExamLink? examLink;

  @override
  ImagePickerWidgetState createState() => ImagePickerWidgetState();
}

class ImagePickerWidgetState extends State<ImagePickerWidget> {
  final List<File> _images = [];
  static const mm = '🥦🥦🥦🥦 ImagePickerWidget 🍐';
  bool busy = false;
  bool _useCamera = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _pickImage(_useCamera ? ImageSource.camera : ImageSource.gallery);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      final appDir = await getApplicationDocumentsDirectory();
      final savedImage =
          await image.copy('${appDir.path}/${image.path.split('/').last}');
      var compressedImage = await compressImage(file: savedImage, quality: 80);
      _images.clear();
      setState(() {
        _images.add(compressedImage!);
      });
      pp('$mm ... image picked, compressedImage: ${compressedImage?.path}');
      _startGeminiImageTextChat0();
    }
  }

  // Future _sendImageToAI() async {
  //   pp('$mm _sendImageToAI: ...........................'
  //       ' images: ${_images.length}');
  //   if (_images.isEmpty) {
  //     return;
  //   }
  //   pp('$mm _sendImageToAI: image: ${_images.first.path} - ${await _images.first.length()} bytes');
  //   setState(() {
  //     busy = true;
  //   });
  //   try {
  //     var response = await widget.chatService.sendExamPageImageAndText(
  //         prompt: '${_getPromptContext()}. \n'
  //             '${textEditingController.value.text}',
  //         file: _images.first,
  //         examLinkId: 12345);
  //     pp('$mm _sendImageToAI: ...... Gemini AI has responded! ');
  //     var sb = StringBuffer();
  //     for (var candidate in response.candidates!) {
  //       var content = candidate.content;
  //       List<MyParts>? parts = content?.parts!;
  //       parts?.forEach((MyParts p) {
  //         sb.write(p.text);
  //         sb.write('\n');
  //       });
  //     }
  //     _navigateToGenericImageResponse(_images.first, sb.toString());
  //     pp('$mm ... response: $response');
  //   } catch (e) {
  //     pp('$mm _sendImageToAI: ERROR $e');
  //     if (e is CompressError) {
  //       pp('$mm 👿👿👿👿compress error: ${e.message} 👿👿👿');
  //       pp('${e.stackTrace}');
  //     }
  //     if (mounted) {
  //       showErrorDialog(context, 'Fell down the stairs, Boss! 🍎 $e');
  //     }
  //   }
  //   setState(() {
  //     busy = false;
  //   });
  // }

  String? aiResponseText;
  int totalTokens = 0;
  late gai.GenerativeModel generativeModel;

  void _startGeminiImageTextChat0() async {
    pp('\n\n$mm ... generateContentStream listen .... 🍎 $aiResponseText');

    final model = gai.GenerativeModel(
        model: 'gemini-pro-vision',
        apiKey: ChatbotEnvironment.getGeminiAPIKey(),
        generationConfig: gai.GenerationConfig(temperature: 0));
    const prompt = 'Examine the image and tell me what it contains. '
        'Solve any questions or problems that you find';
    pp('Prompt: $prompt');

    List<gai.Part> dataParts = [];
    dataParts.add(gai.TextPart(prompt));
    for (var img in _images) {
      dataParts.add(gai.DataPart('image/jpeg', img.readAsBytesSync()));
    }

    gai.Content.multi(dataParts);

    final content = [gai.Content.multi(dataParts)];
    // final tokenCount = await model.countTokens(content);
    // print('Token count: ${tokenCount.totalTokens}');

    try {
      pp('\n\n$mm ... generateContent.... 🍎');

      var res = await model.generateContent(content);
      aiResponseText = res.text;
      pp('\n\n$mm ... generateContent: response: 🍎🍎🍎🍎 $aiResponseText 🍎🍎🍎🍎');
      setState(() {});
      _navigateToGenericImageResponse(_images.first, aiResponseText!);
    } catch (e, s) {
      pp('$mm $e $s');
    }
  }

  _startGeminiImageTextChat() async {
    const mx = '😎😎😎 ';
    pp('\n\n$mm ...$mx  _startGeminiImageTextChat .... 🍎 with picture');
    setState(() {
      aiResponseText = null;
    });

    totalTokens = 0;
    List<gai.TextPart> userTextParts = [];
    List<gai.TextPart> modelTextParts = [];

    try {
      userTextParts
          .add(gai.TextPart('Examine the image and tell me what it contains. '
              'Solve any questions or problems that you find'));
      modelTextParts.add(gai.TextPart('I am a student tutor and assistant'));
      //
      pp('$mm ... $mx  ... sending prompt with image(s) for Gemini: \n ');

      final model = gai.GenerativeModel(
          model: 'gemini-vision-pro',
          apiKey: ChatbotEnvironment.getGeminiAPIKey());
      List<gai.Content> contents = [];
      List<gai.DataPart> dataParts = [];
      for (var img in _images) {
        dataParts.add(gai.DataPart('image/jpeg', img.readAsBytesSync()));
      }

      contents.add(gai.Content('model', modelTextParts));
      contents.add(gai.Content('user', dataParts));
      contents.add(gai.Content('user', userTextParts));

      // gai.CountTokensResponse countTokensResponse =
      // await model.countTokens(contents);
      // pp('$mm CountTokensResponse:  🌍🌍🌍🌍tokens: ${countTokensResponse
      //     .totalTokens}  🌍🌍🌍🌍');

      final gai.GenerateContentResponse response =
          await model.generateContent(contents);
      if (response.candidates.first.finishMessage == 'stop' ||
          response.candidates.first.finishMessage == 'STOP') {
        aiResponseText = response.text;
        if (isValidLaTeXString(aiResponseText!)) {
          // aiResponseText = addNewLinesToLaTeXHeadings(aiResponseText!);
          //_showMarkdown = false;
        }
      } else {
        pp('$mm BAD FINISH REASON: ${response.candidates.first.finishMessage}'
            ' ${response.candidates.first.finishReason.toString()}');
        if (mounted) {
          showErrorDialog(context,
              'SgelaAI could not help you at this time. Try again later.');
        }
      }
      pp('$mm $mx ...... Gemini says: $aiResponseText');
      _navigateToGenericImageResponse(_images.first, aiResponseText!);
    } catch (e, s) {
      pp('$mm ERROR: $e $s');
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
  }

  _navigateToGenericImageResponse(File file, String text) {
    var isLatex = isValidLaTeXString(text);
    pp('$mm ... _navigateToGenericImageResponse, '
        'isValidLaTeXString: $isLatex');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenericImageResponseViewer(
            text: text, isLaTex: isLatex, file: file),
      ),
    );
  }

  String _getPromptContext() {
    var sb = StringBuffer();
    sb.write('Tell me, in detail, what you see in the image. \n');
    sb.write(
        'Keep the discussion and solution at high school or freshman college level. \n');
    sb.write(
        'If it is mathematics or physics, solve the problem and return response in LaTex format. \n');
    sb.write(
        'If it is any other subject return response in markdown format. \n');
    sb.write('Focus on educational aspects of the image contents. \n');
    sb.write(
        'Use headings and paragraphs in markdown or LaTex formatted response');
    return sb.toString();
  }

  final List<String> _captions = [];
  TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SgelaAI Images'),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_useCamera
                        ? 'Use the CAMERA'
                        : 'Get Picture from GALLERY'),
                    gapW16,
                    Switch(
                      value: _useCamera,
                      onChanged: (value) {
                        setState(() {
                          _useCamera = value;
                        });
                        _pickImage(
                            value ? ImageSource.camera : ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ],
            )),
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Say something!',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _captions[index] = value;
                        });
                      },
                      controller: textEditingController,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        _images[index],
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 48,
            child: Center(
              child: ToolBar(
                onCamera: () {
                  _pickImage(
                      _useCamera ? ImageSource.camera : ImageSource.gallery);
                },
                onSubmit: () {
                  if (_images.isNotEmpty) {
                    _startGeminiImageTextChat0();
                  }
                },
                showSubmit: _images.isNotEmpty,
                isCamera: _useCamera,
              ),
            ),
          ),
          busy
              ? const Positioned(
                  top: 200,
                  left: 20,
                  right: 20,
                  child: BusyIndicator(
                    caption:
                        'SgelaAI is checking the picture out. Please wait.',
                  ))
              : gapW8,
        ],
      ),
    );
  }
}

class ToolBar extends StatelessWidget {
  const ToolBar(
      {super.key,
      required this.onCamera,
      required this.onSubmit,
      required this.showSubmit,
      required this.isCamera});

  final Function() onCamera;
  final Function() onSubmit;
  final bool showSubmit, isCamera;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          gapW4,
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              style: const ButtonStyle(
                elevation: MaterialStatePropertyAll(8),
              ),
              onPressed: () {
                onCamera();
              },
              icon: Icon(isCamera ? Icons.camera_alt : Icons.list),
              label: Text(isCamera ? 'Take Picture' : 'Photo Gallery'),
            ),
          ),
          gapW16,
          showSubmit
              ? SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    style: const ButtonStyle(
                      elevation: MaterialStatePropertyAll(8),
                    ),
                    onPressed: () {
                      onSubmit();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                )
              : gapW8,
          gapW16,
        ],
      ),
    );
  }
}
