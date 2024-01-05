import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:edu_chatbot/data/exam_page_image.dart';
// import 'package:http/http.dart' as http;

import '../data/exam_link.dart';
import '../data/subject.dart';
import '../repositories/repository.dart';
import '../util/functions.dart';
import 'local_data_service.dart';

class DownloaderService {
  final Repository repository;
  final LocalDataService localDataService;

  DownloaderService(this.repository, this.localDataService);

  static const mm = '🐸🐸🐸🐸 DownloaderService(Isolate) 🐸';

  final StreamController<int> _controller = StreamController.broadcast();

  Stream<int> get downloaderStream => _controller.stream;

  Future<void> downloadSubjectExamPageImages(Subject subject) async {
    pp('$mm download examLink images for subject: ${subject.title} exams');
    var links = await repository.getExamLinks(subject.id!, true);
    var examPageImages = await downloadExams(links);
    pp('$mm downloaded examLink images for subject:'
        ' ${subject.title} exams: 🍎🍎 ${examPageImages.length}');

  }

  Future<List<ExamPageImage>> downloadExams(List<ExamLink> examLinks) async {
    pp('$mm download examLink images for ${examLinks.length} exams ......................');

    List<ExamPageImage> images = [];
    for (var link in examLinks) {
      images.addAll(await getExamImages(link));
    }
    pp('$mm 🌿🌿🌿total exam page images downloaded for ${examLinks.length} exams: '
        '🍎🍎 ${images.length} 🌿🌿🌿');
    return images;
  }

  Future<List<ExamPageImage>> getExamImages(ExamLink examLink) async {
    pp('$mm download examLink images for ${examLink.title} .....');
    return await repository.getExamPageImages(examLink, false);

  }

  static Future<String> _heavyComputation(Map<String, dynamic> json) async {
    pp('$mm 🌿🌿🌿_heavyComputation(called by Isolate.run) '
        'starting ... 🌿🌿🌿🌿🌿🌿 json: $json');

    List<ExamPageImage> examPageImages = [];
    var url = json['pageImageZipUrl'];
    var files = await downloadZippedFileWithDio(url);
    int index = 0;
    for (var file in files) {
        var epi = ExamPageImage(json['id'], null,
            json['pageImageZipUrl'], file.readAsBytesSync(),
            index, 'png');
        examPageImages.add(epi);
        index++;
    }
    var jsonString = jsonEncode(examPageImages);
    pp('$mm 🌿🌿🌿_heavyComputation(called by Isolate.run) '
        'jsonString = ${jsonString.length} bytes ... 🌿🌿🌿🌿🌿🌿');
    return jsonString;
  }

  //  static Future<List<File>> downloadZippedFile(String url) async {
  //   pp('$mm .... downloading zipped file .......................... url: $url ');
  //   try {
  //     var response = await http.get(Uri.parse(url));
  //     var bytes = response.bodyBytes;
  //     final file = File('file_${DateTime.now().toIso8601String()}.png');
  //     file.writeAsBytesSync(bytes);
  //     return unpackZipFile(file);
  //   } catch (e) {
  //     pp('Error downloading file: $e');
  //     rethrow;
  //   }
  // }
  static Future<dynamic> downloadZippedFileWithDio(
      String url) async {
    try {
      var dio = Dio();
      Response response;
      response = await dio.download(url,
          'file${DateTime.now().toIso8601String()}.png');

      pp('$mm dio network response: 🥬🥬🥬 status code: ${response.statusCode}');
      return response.data;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }
   static List<File> unpackZipFile(File zipFile) {
    final destinationDirectory = Directory('zipFiles');

    if (!zipFile.existsSync()) {
      throw Exception('Zip file does not exist');
    }

    if (!destinationDirectory.existsSync()) {
      destinationDirectory.createSync(recursive: true);
    }

    final archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());

    final files = <File>[];

    for (final file in archive) {
      final filePath = '${destinationDirectory.path}/${file.name}';
      final outputFile = File(filePath);

      if (file.isFile) {
        outputFile.createSync(recursive: true);
        outputFile.writeAsBytesSync(file.content as List<int>);
        files.add(outputFile);
      } else {
        outputFile.createSync(recursive: true);
        files.add(outputFile);
      }
    }

    return files;
  }
}
