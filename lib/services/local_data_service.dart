import 'dart:async';

import 'package:edu_chatbot/data/youtube_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/exam_link.dart';
import '../data/exam_page_content.dart';
import '../util/functions.dart';

class LocalDataService {
  static const mm = '💙💙💙💙 LocalDataService 💙';

  late Database db;

  Future init() async {
    pp('$mm initialize sqlite ...');

    db = await openDatabase(
      join(await getDatabasesPath(), 'skunk047db'),
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
    bool imageTableExists = await _tableExists('exam_page_contents');
    if (!imageTableExists) {
      try {
        await db.execute('''
                CREATE TABLE exam_page_contents (
                  id INTEGER PRIMARY KEY,
                  examLinkId INTEGER,
                  pageIndex INTEGER,
                  text TEXT,
                  title TEXT,
                  pageImageUrl TEXT,
                  mimeType VARCHAR(6),
                  uBytes BLOB,
                  UNIQUE(examLinkId, pageIndex) ON CONFLICT REPLACE

                )
              ''');
        pp('$mm Created the exam_page_contents table 🔵🔵');
      } catch (e) {
        pp('$mm exam_page_contents: error: 👿👿👿$e');
      }
    }
  }

  Future<bool> _tableExists(String tableName) async {
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );
    return tables.isNotEmpty;
  }

  Future<void> addExamPageContents(
      List<ExamPageContent> examPageContents) async {
    for (var value in examPageContents) {
      await addExamPageContent(value);
    }
  }

  Future<void> addExamPageContent(ExamPageContent image) async {
    try {
      var tMap = {
        'id': image.id!,
        'examLinkId': image.examLinkId!,
        'pageIndex': image.pageIndex,
        'text': image.text,
        'uBytes': image.uBytes,
        'pageImageUrl': image.pageImageUrl,
        'title': image.title,
      };
      await db.insert('exam_page_contents', tMap);
      pp('$mm ExamPageContent added to local database 🍎🍎 '
          'pageIndex: ${image.pageIndex}');
    } catch (e) {
      pp("$mm addExamPageContent: ERROR: 👿${e.toString()} 👿🏽");
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

  Future<List<ExamPageContent>> getExamPageContents(int examLinkId) async {
    List<ExamPageContent> examPageContents = [];
    List<Map<String, dynamic>> maps = await db.query(
      'exam_page_contents',
      columns: ["id", "pageIndex", "uBytes", "text", "title", "pageImageUrl"],
      where: "examLinkId = ?",
      whereArgs: [examLinkId],
    );

    if (maps.isNotEmpty) {
      for (var element in maps) {
        var mapWithStrings = element.cast<String, dynamic>();
        examPageContents.add(ExamPageContent.fromJson(mapWithStrings));
      }
    }

    pp('$mm getExamPageContent: found on local db: ${examPageContents.length}');
    if (examPageContents.isEmpty) {}
    return examPageContents;
  }
}

class ExamPageImageCount {
  ExamLink? examLink;
  int? count;

  ExamPageImageCount(this.examLink, this.count);
}
