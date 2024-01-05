import 'dart:io';

import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:edu_chatbot/ui/generic_image_response_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/chat_service.dart';
import '../util/functions.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key, required this.chatService});

  final ChatService chatService;

  @override
  ImagePickerWidgetState createState() => ImagePickerWidgetState();
}

class ImagePickerWidgetState extends State<ImagePickerWidget> {
  final List<File> _images = [];
  static const mm = '🥦🥦🥦🥦 ImagePickerWidget 🍐';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _pickImage(ImageSource.gallery);
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
      _sendImageToAI();
    }
  }

  Future _sendImageToAI() async {
    pp('$mm _sendImageToAI: ...........................'
        ' images: ${_images.length}');
    if (_images.isEmpty) {
      return;
    }
    pp('$mm _sendImageToAI: image: ${_images.first.path} - ${await _images.first.length()} bytes');
    setState(() {
      busy = true;
    });
    try {
      var responseText = await widget.chatService.sendGenericImageTextPrompt(
          _images.first,
          '${_getPromptContext()}. \n'
          '${textEditingController.value.text}');
      pp('$mm _sendImageToAI: ...... Gemini AI has responded! ');
      _navigateToGenericImageResponse(_images.first, responseText);
      pp('$mm ... response: $responseText');
    } catch (e) {
      pp('$mm _sendImageToAI: ERROR $e');
      if (e is CompressError) {
        pp('$mm 👿👿👿👿compress error: ${e.message} 👿👿👿');
        pp('${e.stackTrace}');
      }
      if (mounted) {
        showErrorDialog(context, 'Fell down, Boss! 🍎 $e');
      }
    }
    setState(() {
      busy = false;
    });
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
    sb.write('Use headings and paragraphs in markdown formatted response');
    return sb.toString();
  }

  bool _useCamera = false;
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
                    child: Image.file(
                      _images[index],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 8,
            child: Center(
              child: ToolBar(
                onCamera: () {
                  _pickImage(
                      _useCamera ? ImageSource.camera : ImageSource.gallery);
                },
                onSubmit: () {
                  if (_images.isNotEmpty) {
                    _sendImageToAI();
                  }
                },
                showSubmit: _images.isNotEmpty,
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
      required this.showSubmit});

  final Function() onCamera;
  final Function() onSubmit;
  final bool showSubmit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          gapW16,
          SizedBox(
            width: 160,
            child: ElevatedButton.icon(
              style: const ButtonStyle(
                elevation: MaterialStatePropertyAll(8),
              ),
              onPressed: () {
                onCamera();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Get Image'),
            ),
          ),
          gapW16,
          showSubmit
              ? SizedBox(
                  width: 160,
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
