import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:edu_chatbot/data/gemini_response_rating.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/util/dio_util.dart';
import 'package:edu_chatbot/util/environment.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../data/exam_document.dart';
import '../data/exam_link.dart';
import '../data/exam_page_image.dart';
import '../util/functions.dart';
import '../util/image_file_util.dart';

class Repository {
  final DioUtil dioUtil;

  final Dio dio;
  final LocalDataService localDataService;

  static const mm = '💦💦💦💦 Repository 💦';

  Repository(this.dioUtil, this.localDataService, this.dio);

  Future<List<ExamPageImage>> getExamPageImages(
      ExamLink examLink, bool useStream) async {
    pp('$mm ... getExamPageImages ....');
    List<ExamPageImage> images = [];
    try {
      images = await localDataService.getExamImages(examLink.id!);
      if (images.isNotEmpty) {
        pp('$mm ... getExamPageImages .... found in local store: ${images.length}'
            '... no need to download ');
        return images;
      }
      var imageFiles = await ImageFileUtil.getFiles(examLink);
      int index = 1;
      for (var imgFile in imageFiles) {
        var img = ExamPageImage(examLink.id!, null,
            examLink.pageImageZipUrl, imgFile.readAsBytesSync(),
            index, getMimeType(imgFile));
        await localDataService.addExamImage(img);
        images.add(img);
        index++;
      }
      if (useStream) {
        _streamController.sink.add(index);
      }
      pp('$mm ... getExamPageImages .... from remote store: ${images.length}');

      return images;
    } catch (e) {
      // Handle any errors
      pp('Error calling addExamImage API: $e');
      rethrow;
    }
  }

  Future<File> createImageFileFromBytes(List<int> bytes, String filePath) async {
    final file = File(filePath);

    // Determine the file extension based on the content
    String fileExtension = '';
    if (bytes.length >= 4) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        fileExtension = '.png';
      } else if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[bytes.length - 2] == 0xFF && bytes[bytes.length - 1] == 0xD9) {
        fileExtension = '.jpg';
      }
    }

    // If the file extension is still empty, fallback to .jpeg
    if (fileExtension.isEmpty) {
      fileExtension = '.jpeg';
    }

    // Append the file extension to the file path
    String finalFilePath = filePath + fileExtension;

    await file.writeAsBytes(bytes);
    return file.renameSync(finalFilePath);
  }
  String getMimeType(File file) {
    final mimeTypeResolver = MimeTypeResolver();
    final mimeType = mimeTypeResolver.lookup(file.path);
    return mimeType ?? 'application/octet-stream';
  }
  Future<List<GeminiResponseRating>> getRatings(int examLinkId) async {
    pp('$mm ... getRatings ....');
    List<GeminiResponseRating> ratings = [];
    try {
      String urlPrefix = ChatbotEnvironment.getSkunkUrl();
      var path = '${urlPrefix}links/getResponseRatings';
      List res = await dioUtil.sendGetRequest(path, {'examLinkId': examLinkId});
      for (var r in res) {
        ratings.add(GeminiResponseRating.fromJson(r));
      }

      pp('$mm ... getRatings .... from remote store: ${ratings.length}');
      return ratings;
    } catch (e) {
      // Handle any errors
      pp('Error calling addExamImage API: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> addRating(GeminiResponseRating rating) async {
    pp('$mm .......... addRating: ${rating.rating}');
    String urlPrefix = ChatbotEnvironment.getSkunkUrl();
    var path = '${urlPrefix}links/addResponseRating';
    try {
      List res = await dioUtil.sendPostRequest(path, rating.toJson());
      for (var value in res) {
        pp('$mm .......... addRating response is Firestore id: $value');

      }
      return res;
    } catch (e) {
      // Handle any errors
      pp('Error calling addResponseRating API: $e');
      rethrow;
    }
  }

  final StreamController<int> _streamController = StreamController.broadcast();

  Stream<int> get pageStream => _streamController.stream;

  static Future<List<File>> downloadFile(String url) async {
    pp('$mm .... downloading file .......................... ');
    try {
      var response = await http.get(Uri.parse(url));
      var bytes = response.bodyBytes;
      var mFile = File('someFile');
      mFile.readAsBytesSync();
      return unpackZipFile(mFile);
    } catch (e) {
      pp('Error downloading file: $e');
      rethrow;
    }
  }

  Future<List<Subject>> getSubjects(bool refresh) async {
    var list = <Subject>[];
    try {
      if (refresh) {
        list = await _downloadSubjects();
      } else {
        list = await localDataService.getSubjects();
        if (list.isEmpty) {
          list = await _downloadSubjects();
        }
      }

      pp("$mm Subjects found: ${list.length} ");

      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ExamLink>> getExamLinks(int subjectId, bool refresh) async {
    List<ExamLink> list = [];
    try {
      if (refresh) {
        list = await _downloadExamLinks(subjectId);
      } else {
        list = await localDataService.getExamLinksBySubject(subjectId);
        if (list.isEmpty) {
          list = await _downloadExamLinks(subjectId);
        }
      }

      pp("$mm  Exam links found: ${list.length}, "
          "subjectId: $subjectId ");

      return list;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }
  Future<List<ExamDocument>> getExamDocuments(bool refresh) async {
    if (refresh) {
      return _downloadExamDocuments();
    } else {
      var list = await localDataService.getExamDocuments();
      if (list.isEmpty) {
        return _downloadExamDocuments();
      }
      return list;
    }
  }

    Future<List<ExamLink>> getExamLinksByDocument(Subject subject, String documentTitle, bool refresh) async {
    List<ExamLink> list = [];
    List<ExamLink> filtered = [];

    try {
      if (refresh) {
        list = await _downloadExamLinks(subject.id!);
      } else {
        list = await localDataService.getExamLinksBySubject(subject.id!);
        if (list.isEmpty) {
          list = await _downloadExamLinks(subject.id!);
        }
      }
      for (var link in list) {
        if (link.documentTitle! == documentTitle) {
          filtered.add(link);
        }
      }
      pp("$mm  Exam links filtered; found: ${filtered.length}, "
          "subject: ${subject.toJson()} ");

      return filtered;
    } catch (e) {
      pp(e);
      rethrow;
    }
  }

  Future<List<ExamLink>> _downloadExamLinks(int subjectId) async {
    pp('$mm downloading examLinks ...');

    List<ExamLink> examLinks = [];
    var url = ChatbotEnvironment.getSkunkUrl();
    var res = await dioUtil.sendGetRequest(
        '${url}links/getSubjectExamLinks', {'subjectId': subjectId});
    // Assuming the response data is a list of examLinks

    List<dynamic> responseData = res;
    for (var linkData in responseData) {
      var map = {
        "id": linkData["id"],
        "title": linkData["title"],
        "link": linkData["link"],
        "subjectTitle": linkData["subject"]["title"],
        "subjectId": linkData["subject"]["id"],
        "examText": linkData["examText"],
        "pageImageZipUrl": linkData["pageImageZipUrl"],
        "documentTitle": linkData["examDocument"]["title"]
      };
      ExamLink examLink = ExamLink.fromJson(map);
      examLinks.add(examLink);
    }

    pp("$mm  Exam links found: ${examLinks.length}, "
        "subjectId: $subjectId ");
    if (examLinks.isNotEmpty) {
      localDataService.addExamLinks(examLinks);
    }
    return examLinks;
  }

  Future<List<Subject>> _downloadSubjects() async {
    pp('$mm downloading subjects ...');
    List<Subject> subjects = [];
    var url = ChatbotEnvironment.getSkunkUrl();
    var res = await dioUtil.sendGetRequest('${url}links/getSubjects', {});
    // Assuming the response data is a list of subjects

    List<dynamic> responseData = res;
    for (var linkData in responseData) {
      Subject examLink = Subject.fromJson(linkData);
      subjects.add(examLink);
    }

    pp("$mm  Subjects links found: ${subjects.length}, ");
    if (subjects.isNotEmpty) {
      localDataService.addSubjects(subjects);
    }
    return subjects;
  }

  Future<List<ExamDocument>> _downloadExamDocuments() async {
    pp('$mm downloading docs ...');
    List<ExamDocument> docs = [];
    var url = ChatbotEnvironment.getSkunkUrl();
    var res = await dioUtil.sendGetRequest('${url}links/getExamDocuments', {});
    // Assuming the response data is a list of docs

    List<dynamic> responseData = res;
    for (var linkData in responseData) {
      ExamDocument examLink = ExamDocument.fromJson(linkData);
      docs.add(examLink);
    }

    pp("$mm  ExamDocuments found: ${docs.length}, ");
    if (docs.isNotEmpty) {
      localDataService.addExamDocuments(docs);
    }
    return docs;
  }


  Future<File> downloadOriginalExamPDF(ExamLink examLink) async {
    //todo - check if exists
    Response<List<int>> response = await dio.get<List<int>>(
      examLink.link!,
      options: Options(responseType: ResponseType.bytes),
    );

    // Create a temporary directory to extract the zip file
    Directory tempDir = await Directory.systemTemp.createTemp();
    String tempPath = tempDir.path;

    // Save the downloaded zip file to the temporary directory

    String pdfPath = path.join(tempPath, 'exam_${examLink.id}.pdf');
    File pdfFile = File(pdfPath);
    if (response.data != null) {
      await pdfFile.writeAsBytes(response.data!, flush: true);
    }

    // Extract the zip file
    pp("$mm  Exam pdf file saved "
        " 💙 $pdfPath length: ${(pdfFile.length)} bytes");
    return pdfFile;
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
