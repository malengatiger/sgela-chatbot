import 'dart:async';

import 'package:edu_chatbot/data/exam_page_image.dart';
import 'package:edu_chatbot/data/youtube_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/exam_link.dart';
import '../util/functions.dart';

class LocalDataService {
  static const mm = '💙💙💙💙 LocalDataService 💙';

  late Database db;

  Future init() async {
    pp('$mm initialize sqlite ...');

    db = await openDatabase(
      join(await getDatabasesPath(), 'skunk046db'),
      version: 1,
    );
    pp('$mm SQLite Database is open: ${db.isOpen} 🔵🔵 ${db.path}');
    await _createTables();
  }

  Future<void> _createTables() async {
    // Check if the "youtube" table exists
    bool youtubeTableExists = await _tableExists('youtube');
    if (!youtubeTableExists) {
      try {
        await db.execute('''
                CREATE TABLE youtube (
                  id INTEGER PRIMARY KEY,
                  title TEXT,
                  description TEXT,
                  channelId TEXt,
                  videoId TEXT,
                  playlistId TEXT,
                  videoUrl TEXT,
                  channelUrl TEXT,
                  playlistUrl TEXT,
                  thumbnailHigh TEXT,
                  thumbnailMedium TEXT,
                  thumbnailDefault TEXT,
                  subjectId TEXT

                )
              ''');
        pp('$mm Created the youtube table 🔵🔵');
      } catch (e) {
        pp('$mm youtubeTableExists: 👿👿👿$e');
      }
    }

    // Check if the "exam_images" table exists
    bool imageTableExists = await _tableExists('exam_images');
    if (!imageTableExists) {
      try {
        await db.execute('''
                CREATE TABLE exam_images (
                  id INTEGER PRIMARY KEY,
                  downloadUrl TEXT,
                  mimeType VARCHAR(6),
                  bytes BLOB,
                  examLinkId INTEGER,
                  pageIndex INTEGER,
                  UNIQUE(examLinkId, pageIndex) ON CONFLICT REPLACE

                )
              ''');
        pp('$mm Created the exam_images table 🔵🔵');
      } catch (e) {
        pp('$mm exam_images: error: 👿👿👿$e');
      }
    }
  }

  Future<bool> _tableExists(String tableName) async {
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );
    return tables.isNotEmpty;
  }

  Future<void> addExamImage(ExamPageImage image) async {
    try {
      await db.insert('exam_images', image.toJson());
      pp('$mm ExamPageImage added to local database 🍎🍎 pageIndex: ${image.pageIndex}');
    } catch (e) {
      pp("$mm addExamImage: ERROR: 👿${e.toString()} 👿🏽");
    }
  }

  Future addYouTubeData(List<YouTubeData> youTubeData) async {
    pp('$mm addYouTubeData to sqlite ...  😎 ${youTubeData.length}  😎');
    int cnt = 0;
    for (var ytd in youTubeData) {
      try {
        await db.insert('youtube', ytd.toJson());
        cnt++;
        pp('$mm YoutubeData #$cnt added to local db, '
            'id: 🍎${ytd.id} 🔵🔵 title: ${ytd.title}');
      } catch (e) {
        pp("$mm addYouTubeData: ERROR: 👿${e.toString()} 👿🏽");
      }
    }
  }

  Future<List<ExamPageImage>> getExamImages(int examLinkId) async {
    List<ExamPageImage> examImages = [];
    List<Map<String, dynamic>> maps = await db.query(
      'exam_images',
      columns: ["id", "pageIndex", "bytes","mimeType"],
      where: "examLinkId = ?",
      whereArgs: [examLinkId],
    );

    if (maps.isNotEmpty) {
      for (var element in maps) {
        var mapWithStrings = element.cast<String, dynamic>();
        examImages.add(ExamPageImage.fromJson(mapWithStrings));
      }
    }

    pp('$mm getExamImages: found on local db: ${examImages.length}');
    return examImages;
  }
}

class ExamPageImageCount {
  ExamLink? examLink;
  int? count;

  ExamPageImageCount(this.examLink, this.count);
}
