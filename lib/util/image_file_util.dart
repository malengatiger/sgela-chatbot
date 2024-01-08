import 'dart:io';

import 'package:archive/archive.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

import '../data/exam_link.dart';
import 'package:http/http.dart' as http;

import '../data/exam_page_image.dart';
import 'functions.dart';

class ImageFileUtil {
  static const mm = '🌿🌿🌿 ImageFileUtil 😎😎';

  static Future<List<File>> getFiles(ExamLink examLink) async {
    return await downloadFile(examLink.pageImageZipUrl!);

  }
  static Future<List<File>> downloadFile(String url) async {
    pp('$mm .... downloading file .......................... ');
    try {
      var response = await http.get(Uri.parse(url));
      var bytes = response.bodyBytes;
      Directory tempDir = Directory.systemTemp;
      var mFile = File('${tempDir.path}/someFile.zip');
      mFile.writeAsBytesSync(bytes);
      return unpackZipFile(mFile);
    } catch (e) {
      pp('Error downloading file: $e');
      rethrow;
    }
  }  static Future<List<File>> unpackZipFile(File zipFile) async {
    Directory destinationDirectory = Directory.systemTemp;

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
    pp('$mm .... files unpacked: ${files.length} ');
    for (var value in files) {
      pp('$mm unpacked file: 💙💙 ${(await value.length())/1024}K 💙💙 ${value.path}');
    }

    return files;
  }

  static Future<List<File>> getPageImageFiles(ExamLink examLink, DownloaderService downloaderService) async {
    var images = await downloaderService.getExamImages(examLink);
    pp('$mm examPageImages found for conversion: ${images.length}');
    int index = 0;
    final appDir = await getApplicationDocumentsDirectory();
    List<File> realFiles = [];

    for (var img in images) {
      var pathSuffix = '/image_${examLink.id!}_${img.pageIndex}.png';
      var path0 = '${appDir.path}$pathSuffix';
      File x = File(path0);
      if (x.existsSync()) {
        realFiles.add(x);
      } else {
        var mFile =
        await ImageFileUtil.createImageFileFromBytes(img.bytes!, pathSuffix);
        realFiles.add(mFile);
      }
      index++;
    }
    pp('$mm examPageImages turned into files: ${realFiles.length}');
    return realFiles;
  }

  static Future<List<File>> convertPageImageFiles(ExamLink examLink, List<ExamPageImage> images) async {
    pp('$mm examPageImages found for conversion: ${images.length}');
    int index = 0;
    final appDir = await getApplicationDocumentsDirectory();
    List<File> realFiles = [];

    for (var img in images) {
      var pathSuffix = '/image_${examLink.id!}_${img.pageIndex}.png';
      var path0 = '${appDir.path}$pathSuffix';
      File x = File(path0);
      if (x.existsSync()) {
        realFiles.add(x);
      } else {
        var mFile =
        await ImageFileUtil.createImageFileFromBytes(img.bytes!, pathSuffix);
        realFiles.add(mFile);
      }
      index++;
    }
    pp('$mm examPageImages turned into files: ${realFiles.length}');
    return realFiles;
  }

  static Future<File> createImageFileFromBytes(List<int> bytes, String filePath) async {
    final appDir = await getApplicationSupportDirectory();
    final file = File('${appDir.path}/$filePath');

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
    // Create a copy of the file with the desired file path
    File copiedFile = await file.copy('${appDir.path}/$finalFilePath');

    return copiedFile;
  }
  static String getMimeType(File file) {
    final mimeTypeResolver = MimeTypeResolver();
    final mimeType = mimeTypeResolver.lookup(file.path);
    return mimeType ?? 'image/png';
  }

  static http.MultipartFile createMultipartFile(
      List<int> bytes, String fieldName, String filename) {
    // Create a byte stream from the bytes list
    var stream = http.ByteStream.fromBytes(bytes);
    // Get the length of the byte stream
    var length = bytes.length;

    // Create the multipart file object
    var multipartFile =
    http.MultipartFile(fieldName, stream, length, filename: filename);

    return multipartFile;
  }

  static Future<File> getFileFromBytes(List<int> bytes, String path) async {
    Directory dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$path');
    file.writeAsBytesSync(bytes);
    return file;

  }
  static Future<File> getFileFromString(String content, String path) async {
    Directory dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$path');
    file.writeAsStringSync(content, mode: FileMode.write);
    pp('$mm getFileFromString: ${file.path} - ${await file.length()} bytes');
    return file;

  }
  Future<File> scaleDownImage(File imageFile) async {
    pp('$mm Compress file size: ${await imageFile.length()}');

    final fileSize = await imageFile.length();
    if (fileSize <= 1024 * 1024) {
      pp('$mm Image size is already less than or equal to 1 MB, no need to scale down');
      return imageFile;
    }

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      imageFile.path,
      quality: 85,
      format: imageFile.path.endsWith('.png')
          ? CompressFormat.png
          : CompressFormat.jpeg,
    );
    final filePath = compressedFile?.path;
    var file = File(filePath!);
    pp('$mm Compressed file size: ${await file.length()}');
    return file;
  }
}
