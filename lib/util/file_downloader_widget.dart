import 'dart:io';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/util/environment.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class FileDownloaderUtil {
  static const mm = '🍎🍎🍎🍎🍎🍎 FileDownloaderUtil 🍐';

  static Future<File?> downloadFile(String url) async {
    if (Platform.isAndroid) {
      // You can download a single file
      var file = await FileDownloader.downloadFile(
        url: url,
        onDownloadCompleted: (String path) {
          pp('$mm ... FILE DOWNLOADED TO PATH: $path');
        },
        onDownloadError: (String error) {
          pp('$mm DOWNLOAD ERROR: $error url: $url');
          throw Exception('File download failed: $error');
        },
      );

      return file;
    } else {
      throw Exception('File download is only supported on Android devices.');
    }
  }

  static Future<List<File?>> downloadFiles(List<ExamPageContent> examPageContents) async {
    if (Platform.isAndroid) {
      FileDownloader.setLogEnabled(ChatbotEnvironment.isChatDebuggingEnabled());
      FileDownloader.setMaximumParallelDownloads(25);

      List<String> urls = [];
      for (var page in examPageContents) {
        if (page.pageImageUrl != null) {
          urls.add(page.pageImageUrl!);
        }
      }
      final List<File?> result = await FileDownloader.downloadFiles(
        urls: urls,
        isParallel: true,
        onAllDownloaded: () {
          pp('$mm all files are downloaded: ${examPageContents.length}');
        },

      );

      pp('$mm downloads complete: ${result.length} files');
      return result;
    } else {
      throw Exception('File download is only supported on Android devices.');
    }
  }
}

class FileBag {
  late File file;
  late String url;

  FileBag(this.file, this.url);
}