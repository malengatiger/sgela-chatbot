import 'package:edu_chatbot/util/functions.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import '../util/dio_util.dart';
import '../util/environment.dart';

class ConversionService {
  static const mm = '🔵🔵🔵🔵 ConversionUtil  🔵🔵';
  static String urlPrefix = ChatbotEnvironment.getGeminiUrl();
  final DioUtil dioUtil;

  ConversionService(this.dioUtil);

//convertToHtmlFromMarkdown
  Future convertToHtmlFromMarkdown(String markdownString, String title, String fileName) async {
    pp('$mm ..... convertToPdfFromMarkdown ....');

    String url =
        '${urlPrefix}converter/convertToHtmlFromMarkdown?markdownString=$markdownString&title=$title';
    File file = await downloadFile(url, 'md', fileName);
    pp('$mm ... convertToHtmlFromMarkdown: ${await file.length()} bytes');
    return file;
  }

  Future convertToPdfFromMarkdown(String markdownString, String title, String fileName) async {
    pp('$mm ..... convertToPdfFromMarkdown ....');

    String url =
        '${urlPrefix}converter/convertToPdfFromMarkdown?markdownString=$markdownString&title=$title';
    File file = await downloadFile(url,'pdf', fileName);
    pp('$mm ... convertToPdfFromMarkdown: ${await file.length()} bytes');
    return file;
  }

  Future convertToHtmlFromLaTeX(String laTexString, String title, String fileName) async {
    pp('$mm ..... convertToHtmlFromLaTeX ....');

    String url =
        '${urlPrefix}converter/convertToHtmlFromLaTeX?laTexString=$laTexString&title=$title';
    File file = await downloadFile(url, 'html', fileName);
    pp('$mm ... convertToHtmlFromLaTeX: ${await file.length()} bytes');
    return file;
  }

  Future convertToPdfFromLaTeX(String laTexString, String title, String fileName) async {
    pp('$mm ..... convertToPdfFromLaTeX ....');

    String url =
        '${urlPrefix}converter/convertToPdfFromLaTeX?laTexString=$laTexString&title=$title';
    File file = await downloadFile(url,'pdf', fileName);
    pp('$mm ... convertToPdfFromLaTeX: ${await file.length()} bytes');
    return file;
  }




  Future<File> convertToMarkdownFile(String text) async {
    pp('$mm ..... convertToMarkdownFile ....');

    var dir = await getApplicationDocumentsDirectory();
    final markdownContent = '# Exam Paper Content\n\n$text';
    final file = File('${dir.path}/text.md');
    file.writeAsStringSync(markdownContent);
    pp('$mm ... Markdown file created at: ${file.path}');
    return file;
  }

  static String convertMarkdownToHtml(String text) {
    var html = markdownToHtml(text);
    return html;
  }

  Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
      pp('$mm File deleted: ${file.path}');
    } else {
      pp('$mm File does not exist: ${file.path}');
    }
  }

  static Future<File> downloadFile(String url, String extension, String fileName) async {
    pp('$mm .... downloading file .........................\n$url ');
    var start = DateTime.now();
    try {
      var response = await http.get(Uri.parse(url));
      var bytes = response.bodyBytes;
      Directory tempDir = Directory.systemTemp;
      var mFile =
          File('${tempDir.path}/$fileName${start.millisecondsSinceEpoch}.$extension');
      mFile.writeAsBytesSync(bytes);
      var end = DateTime.now();
      pp('$mm file: ${(await mFile.length()) / 1024}K bytes '
          'elapsed: ${end.difference(start).inSeconds} seconds');
      return mFile;
    } catch (e) {
      pp('Error downloading file: $e');
      rethrow;
    }
  }
}
