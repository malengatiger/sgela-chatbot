import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dm;
import 'package:edu_chatbot/util/environment.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gm;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../data/exam_page_image.dart';
import '../data/gemini/gemini_response.dart';
import '../util/dio_util.dart';
import '../util/functions.dart' as fun;
import '../util/functions.dart';
import '../util/image_file_util.dart';

class ChatService {
  static const mm = '💜💜💜💜 ChatService';

  final DioUtil dioUtil;

  ChatService(this.dioUtil);

  Future<MyGeminiResponse> sendImageTextPrompt(
      List<ExamPageImage> imageFiles, String prompt) async {
    fun.pp('$mm .... sendImageTextPrompt starting ... '
        'imageFiles: ${imageFiles.length}');
    if (imageFiles.isEmpty) {
      throw Exception('No image files provided');
    }
    String urlPrefix = ChatbotEnvironment.getGeminiUrl();
    String url = '${urlPrefix}textImage/sendTextImagePrompt';
    String param = 'examPageImage';
    if (imageFiles.length > 1) {
      url = '${urlPrefix}textImage/sendTextImagesPrompt';
    }
    fun.pp('$mm sendImageTextPrompt: will send ,,,,, $url ...');

    try {
      http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse(url));
      request.fields['prompt'] = prompt;
      request.fields['mimeType'] = 'image/png';
      request.fields['linkResponse'] = 'true';

      // Add the image files to the request
      for (var i = 0; i < imageFiles.length; i++) {
        var examPageImage = imageFiles[i];
        var file = await ImageFileUtil.createImageFileFromBytes(
            examPageImage.bytes!, 'imageFile');
        var mimeType = ImageFileUtil.getMimeType(file);
        request.fields['mimeType'] = mimeType;

        var multipartFile = ImageFileUtil.createMultipartFile(
            examPageImage.bytes!,
            "file",
            "image_${examPageImage.examLinkId}_i$i.${examPageImage.mimeType}");
        request.files.add(multipartFile);
      }
      // Send the request and get the response
      http.StreamedResponse response = await request.send();
      fun.pp('$mm 🥬🥬🥬🥬 Gemini AI returned response ...'
          'statusCode: ${response.statusCode}  🥬🥬🥬🥬reasonPhrase: ${response.reasonPhrase}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        fun.pp('$mm 👿👿👿👿 sendImageTextPrompt: ERROR, '
            'status: ${response.statusCode} ${response.reasonPhrase} 👿👿👿👿');
        throw Exception('Failed to send AI request: ${response.reasonPhrase}');
      }
      // Read the response as a string
      var responseString = await response.stream.bytesToString();
      // Parse the response string as JSON
      var jsonResponse = jsonDecode(responseString);
      if (jsonResponse is! Map<String, dynamic>) {
        fun.pp(
            '$mm 👿👿👿👿 Gemini AI returned jsonResponse is not a Map 👿👿👿👿');
        throw Exception('Failed to send AI request: jsonResponse is not a Map');
      }
      fun.pp('$mm  🍎🍎🍎 Gemini AI returned jsonResponse ; '
          '$jsonResponse  🍎🍎🍎');

      MyGeminiResponse geminiResponse =
          MyGeminiResponse.fromJson(jsonResponse['response']);
      // Return the parsed JSON response
      return geminiResponse;
    } catch (e) {
      fun.pp('$mm 👿👿👿👿 Gemini AI returned error ... 👿👿👿👿');
      fun.pp(e);
      rethrow;
    }
  }

  Future<MyGeminiResponse> sendExamPageImageAndText(
      {required String prompt,
      required String linkResponse,
      required File file}) async {
    fun.pp('$mm .... sendMultipartRequest starting ... 💙'
        'prompt: $prompt 💙linkResponse: $linkResponse 💙file: ${file.path}');
    try {
      String urlPrefix = ChatbotEnvironment.getGeminiUrl();
      String url = '${urlPrefix}textImage/sendTextImagePrompt';
      String mimeType = ImageFileUtil.getMimeType(file);
      fun.pp('$mm .... mimeType: $mimeType 🍎 '
          'url: $url');
      dm.Dio dio = dm.Dio();
      dm.FormData formData = dm.FormData.fromMap({
        'prompt': prompt,
        'mimeType': mimeType,
        'linkResponse': linkResponse,
        'file': await dm.MultipartFile.fromFile(file.path,
            contentType: MediaType.parse(mimeType)),
      });

      dm.Response response = await dio.post(
        url,
        data: formData,
      );
      pp('$mm ............................ response returned ....');
      if (response.statusCode == 200 || response.statusCode == 201) {
        fun.pp(
            '$mm .... multiPart request is OK! status: ${response.statusCode} '
            ' 🍎 message: ${response.statusMessage} ... ');
        var map = response.data;
        var map2 = map['response'];
        MyGeminiResponse geminiResponse = MyGeminiResponse.fromJson(map2);
        if (geminiResponse.candidates == null ||
            geminiResponse.candidates!.isEmpty) {
          throw Exception(
              '👿👿SgelaAI has no response at this time. Please try again!');
        }
        if (geminiResponse.candidates!.first.finishReason == 'STOP') {
          fun.pp('$mm ...... sendMultipartRequest request is good! 💙💙💙');
          return geminiResponse;
        } else {
          throw Exception(
              '👿👿SgelaAI could not handle your request. Please try again!');
        }
      } else {
        throw Exception('$mm 👿👿👿👿Failed to send multipart request');
      }
    } catch (e) {
      throw Exception('$mm 👿👿👿👿Error sending multipart request: $e');
    }
  }

  Future<String> sendChatPrompt(String prompt) async {
    fun.pp('$mm ...... sendChatPrompt starting ... \n$prompt');
    String urlPrefix = ChatbotEnvironment.getGeminiUrl();
    String url = '${urlPrefix}chats/sendChatPrompt';
    StringBuffer sb = StringBuffer();

    fun.pp('$mm sendChatPrompt: will send $url ...');

    try {
      var resp = await dioUtil.sendGetRequest(url, {'prompt': prompt});

      List? candidates = resp['candidates'];
      if (candidates == null) {
        return 'Unable to generate a response';
      }
      for (var candidate in candidates) {
        var content = candidate['content'];
        List? parts = content['parts'];
        parts?.forEach((p) {
          sb.write(p['text']);
          sb.write('\n');
        });
      }
      // MyGeminiResponse geminiResponse = MyGeminiResponse.fromJson(resp);

      fun.pp(
          '$mm 🥬🥬🥬🥬 sendChatPrompt: 🍎Gemini AI returned response ... 🥬🥬🥬🥬');

      pp('$mm ....... chat response string after parsing: \n${sb.toString()}\n');
      return sb.toString();
    } catch (e) {
      fun.pp(
          '$mm 👿👿👿👿 sendChatPrompt: Gemini AI returned error ... 👿👿👿👿');
      fun.pp(e);
      rethrow;
    }
  }

  Future<String> sendGenericImageTextPrompt(
      File imageFile, String prompt) async {
    var length = await imageFile.length();
    fun.pp('$mm .... sendGenericImageTextPrompt starting ... '
        'imageFile: ${(length / 1024 / 1024).toStringAsFixed(2)} MB');
    var compressed = await compressImage(file: imageFile, quality: 80);
    if (compressed == null) {
      throw Exception('File is fucked!');
    }
    var compLength = await compressed.length();

    if (compLength > (1024 * 1024 * 3)) {
      compressed = await compressImage(file: imageFile, quality: 64);
      if (compressed == null) {
        throw Exception('File is fucked too!');
      }
      var compLength2 = await compressed.length();
      if (compLength2 > (1024 * 1024 * 3)) {
        throw Exception(
            'Image file too big: ${(compLength2 / 1024 / 1024).toStringAsFixed(2)} MB');
      }
    }
    var compLength2 = await compressed.length();

    fun.pp('$mm .... sendGenericImageTextPrompt starting ... '
        'compressed imageFile: ${(compLength2 / 1024 / 1024).toStringAsFixed(2)} MB');
    String urlPrefix = ChatbotEnvironment.getGeminiUrl();
    String url = '${urlPrefix}textImage/sendTextImagePrompt';
    fun.pp('$mm sendImageTextPrompt: will send : $url ...');

    try {
      http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse(url));
      request.fields['prompt'] = prompt;

      // Add the image files to the request
      var stream = http.ByteStream(compressed.openRead());
      // var multipartFile0 = http.MultipartFile("file", stream, length);
      List<int> bytes = await stream.toBytes();
      var multipartFile =
          ImageFileUtil.createMultipartFile(bytes, 'file', 'myfile.jpg');
      fun.pp('$mm sendImageTextPrompt: will send multipartFile :'
          ' ${multipartFile.length} bytes ...');

      request.files.add(multipartFile);
      // Send the request and get the response
      http.StreamedResponse response = await request.send();
      fun.pp('$mm 🥬🥬🥬🥬 Gemini AI returned response ...'
          'statusCode: ${response.statusCode}  🥬🥬🥬🥬reasonPhrase: ${response.reasonPhrase}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        fun.pp('$mm 👿👿👿👿 sendImageTextPrompt: ERROR, '
            'status: ${response.statusCode} ${response.reasonPhrase} 👿👿👿👿');
        throw Exception('Failed to send AI request: ${response.reasonPhrase}');
      }
      // Read the response as a string
      var responseString = await response.stream.bytesToString();
      // Parse the response string as JSON
      var jsonResponse = jsonDecode(responseString);
      if (jsonResponse is! Map<String, dynamic>) {
        fun.pp(
            '$mm 👿👿👿👿 Gemini AI returned jsonResponse is not a Map 👿👿👿👿');
        throw Exception('Failed to send AI request: jsonResponse is not a Map');
      }
      MyGeminiResponse geminiResponse =
          MyGeminiResponse.fromJson(jsonResponse['response']);

      // Return the parsed JSON response
      return getResponseString(geminiResponse);
    } catch (e) {
      fun.pp('$mm 👿👿👿👿 Gemini AI returned error ... 👿👿👿👿');
      fun.pp(e);
      rethrow;
    }
  }

  Future<String> sendImageText(
      ExamPageImage examPageImage, String prompt) async {
    final gemini = gm.Gemini.instance;

    var img = Uint8List.fromList(examPageImage.bytes!);
    var res = await gemini.textAndImage(
        text: prompt,

        /// text
        images: [img]

        /// list of images
        );
    StringBuffer sb = StringBuffer();
    if (res != null) {
      sb.write(res.output);
    }
    return sb.toString();
  }

  Future<String> sendText() async {
    final gemini = Gemini.instance;

    var res = await gemini.chat([
      Content(parts: [Parts(text: 'Help me learn')], role: 'user'),
      Content(
          parts: [Parts(text: 'What do you want to learn?')], role: 'model'),
      Content(parts: [
        Parts(
            text: 'Mathematics, Science, Biology, English, Geography, Climate')
      ], role: 'user'),
    ]);
    StringBuffer sb = StringBuffer();
    if (res != null) {
      sb.write(res.output);
    }
    return sb.toString();
  }
}
