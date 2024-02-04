import 'dart:io';
import 'dart:typed_data';

import 'package:edu_chatbot/data/exam_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import 'package:edu_chatbot/gemini/widgets/chat_input_box.dart';

import '../../data/exam_page_image.dart';
import '../../repositories/repository.dart';
import '../../util/functions.dart';
import '../../util/image_file_util.dart';

class ExamPaperTextAndImage extends StatefulWidget {
  const ExamPaperTextAndImage({super.key, required this.examLink, required this.gemini, required this.repository});

  final ExamLink examLink;
  final Gemini gemini;
  final Repository repository;

  @override
  State<ExamPaperTextAndImage> createState() =>
      _ExamPaperTextAndImageState();
}

class _ExamPaperTextAndImageState extends State<ExamPaperTextAndImage> {
  final ImagePicker picker = ImagePicker();
  final controller = TextEditingController();
  String? searchedText, result;
  bool _loading = false;
  String prompt = '';
  List<File> realFiles = [];
  List<ExamPageImage> images = [];
  List<ExamPageImage> selectedImages = [];
  late PageController _pageController;
  static const mm = '💙💙💙💙 ExamPaperTextAndImage 💙';
  bool busyLoading = false;
  bool busySending = false;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchExamImages();
  }
  Future<void> _fetchExamImages() async {
    pp('$mm .........................'
        'get exam images for display ...');
    setState(() {
      busyLoading = true;
    });

    try {
      // images =
      // await widget.repository.getExamPageImages(widget.examLink, false);
      // realFiles = await ImageFileUtil.convertPageImageFiles(
      //     widget.examLink, images);

    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, 'Failed to load examination images: $e');
      }
    }
    if (mounted) {
      setState(() {
        busyLoading = false;
      });
    }
  }

  Uint8List? selectedImage;

  bool get loading => _loading;

  set loading(bool set) => setState(() => _loading = set);


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (searchedText != null)
          MaterialButton(
              color: Colors.blue.shade700,
              onPressed: () {
                setState(() {
                  searchedText = null;
                  result = null;
                });
              },
              child: Text('search: $searchedText')),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: loading
                      ? Lottie.asset('assets/lottie/ai.json')
                      : result != null
                          ? Markdown(
                              data: result!,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            )
                          : const Center(
                              child: Text('Search something!'),
                            ),
                ),
                if (selectedImage != null)
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.memory(
                        selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
        ChatInputBox(
          controller: controller,
          onClickCamera: () async {
            // Capture a photo.
            final XFile? photo =
                await picker.pickImage(source: ImageSource.camera);

            if (photo != null) {
              photo.readAsBytes().then((value) => setState(() {
                    selectedImage = value;
                  }));
            }
          },
          onSend: () {
            if (controller.text.isNotEmpty && selectedImage != null) {
              searchedText = controller.text;
              controller.clear();
              loading = true;

              widget.gemini.textAndImage(
                  text: searchedText!, images: [selectedImage!]).then((value) {
                result = value?.content?.parts?.last.text;
                loading = false;
              });
            }
          },
        ),
      ],
    );
  }
}
