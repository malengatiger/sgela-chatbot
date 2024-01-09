import 'dart:async';

import 'package:edu_chatbot/data/exam_document.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_image.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/data/youtube_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../util/functions.dart';

class LocalDataService {
  static const mm = '💙💙💙💙 LocalDataService 💙';

  late Database db;

  Future init() async {
    pp('$mm initialize sqlite ...');

    db = await openDatabase(
      join(await getDatabasesPath(), 'skunk042db'),
      version: 1,
    );
    pp('$mm SQLite Database is open: ${db.isOpen} 🔵🔵 ${db.path}');
    await _createTables();
  }

  Future<void> _createTables() async {
    // Check if the "subjects" table exists
    bool subjectsTableExists = await _tableExists('subjects');
    if (!subjectsTableExists) {
      try {
        await db.execute('''
                CREATE TABLE subjects (
                  id INTEGER PRIMARY KEY,
                  title TEXT
                )
              ''');
        pp('$mm Created the subjects table 🔵🔵');
      } catch (e) {
        pp('$mm subjectsTable: error: 👿👿👿$e');
      }
    }

    // Check if the "exam_links" table exists
    bool examLinksTableExists = await _tableExists('exam_links');
    if (!examLinksTableExists) {
      try {
        await db.execute('''
                CREATE TABLE exam_links (
                  id INTEGER PRIMARY KEY,
                  title TEXT,
                  link TEXT,
                  examText TEXT,
                  subjectId INTEGER,
                  subjectTitle TEXT,
                  pageImageZipUrl TEXT,
                  documentTitle TEXT,
                  FOREIGN KEY (subjectId) REFERENCES subjects (id)
                )
              ''');
        pp('$mm Created the exam_links table 🔵🔵');
      } catch (e) {
        pp('$mm examLinksTable: ERROR: 👿👿👿$e');
      }
    }

    // Check if the "subscriptions" table exists
    bool subscriptionsTableExists = await _tableExists('subscriptions');
    if (!subscriptionsTableExists) {
      try {
        await db.execute('''
                CREATE TABLE subscriptions (
                  id INTEGER PRIMARY KEY,
                  country_id INTEGER,
                  organization_id INTEGER,
                  user_id INTEGER,
                  date TEXT,
                  pricing_id INTEGER,
                  subscription_type INTEGER,
                  active_flag INTEGER,
                  FOREIGN KEY (country_id) REFERENCES countries (id),
                  FOREIGN KEY (organization_id) REFERENCES organizations (id),
                  FOREIGN KEY (user_id) REFERENCES users (id),
                  FOREIGN KEY (pricing_id) REFERENCES pricings (id)
                )
              ''');
        pp('$mm Created the subscriptions table 🔵🔵');
      } catch (e) {
        pp('$mm subscriptionsTableExists: 👿👿👿$e');
      }
    }
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
    // Check if the "exam_texts" table exists
    bool textTableExists = await _tableExists('exam_texts');
    if (!textTableExists) {
      try {
        await db.execute('''
                CREATE TABLE exam_texts (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  text TEXT,
                  examLinkId INTEGER
                )
              ''');
        pp('$mm Created the exam_texts table 🔵🔵');
      } catch (e) {
        pp('$mm exam_texts: error: 👿👿👿$e');
      }
    }
    bool textDocsExists = await _tableExists('exam_documents');
    if (!textDocsExists) {
      try {
        await db.execute('''
                CREATE TABLE exam_documents (
                  id INTEGER PRIMARY KEY,
                  title TEXT,
                  link TEXT
                )
              ''');
        pp('$mm Created the exam_documents table 🔵🔵');
      } catch (e) {
        pp('$mm exam_documents: error: 👿👿👿$e');
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

  Future<List<Subject>> getSubjects() async {
    List<Subject> list = [];
    List<Map<dynamic, dynamic>> maps =
        await db.query('subjects', columns: ["id", "title"]);
    if (maps.isNotEmpty) {
      for (var element in maps) {
        var mapWithStrings = element.cast<String, dynamic>();
        list.add(Subject.fromJson(mapWithStrings));
      }
    }
    pp('$mm getSubjects found on local db: ${list.length}');
    return list;
  }

  Future<void> addExamImage(ExamPageImage image) async {
    try {
      await db.insert('exam_images', image.toJson());
      pp('$mm ExamPageImage added to local database 🍎🍎 pageIndex: ${image.pageIndex}');
    } catch (e) {
      pp("$mm addExamImage: ERROR: 👿${e.toString()} 👿🏽");
    }
  }

  Future addSubjects(List<Subject> subjects) async {
    pp('$mm addSubjects to sqlite ...  😎 ${subjects.length}  😎');
    int cnt = 0;
    for (var subject in subjects) {
      try {
        await db.insert('subjects', subject.toJson());
        cnt++;
      } catch (e) {
        pp("$mm addSubjects: ERROR: 👿${e.toString()} 👿🏽");
      }
    }
    pp('$mm subjects added to local db: '
        '🍎$cnt 🔵🔵');
  }

  Future addExamDocuments(List<ExamDocument> examDocuments) async {
    pp('$mm addExamDocuments to sqlite ...  😎 ${examDocuments.length}  😎');
    int cnt = 0;
    for (var subject in examDocuments) {
      try {
        await db.insert('exam_documents', subject.toJson());
        cnt++;
      } catch (e) {
        pp("$mm addExamDocuments: ERROR: 👿${e.toString()} 👿🏽");
      }
    }
    pp('$mm ExamDocuments added to local db: '
        '🍎$cnt 🔵🔵');
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

  Future addExamLinks(List<ExamLink> examLinks) async {
    pp('$mm addExamLinks to sqlite ...  😎 ${examLinks.length}  😎');
    int cnt = 0;
    for (var examLink in examLinks) {
      try {
        var obj = examLink.toJson();
        await db.insert('exam_links', obj);
        // obj['examText'] = '';
        // myPrettyJsonPrint(obj);
        cnt++;

      } catch (e) {
        pp("$mm addExamLinks: ERROR: 🖐🏽${e.toString()} 🖐🏽");
      }
    }
    pp('$mm examLinks added to local db: '
        '🍎$cnt 🔵🔵');
  }

  Future<List<ExamLink>> getExamLinksBySubject(int subjectId) async {
    List<ExamLink> list = [];
    List<Map<String, dynamic>> maps = await db.query(
      'exam_links',
      columns: ["id", "title", "link", "pageImageZipUrl", "documentTitle"],
      where: "subjectId = ?",
      whereArgs: [subjectId],
    );
    if (maps.isNotEmpty) {
      for (var element in maps) {
        var mapWithStrings = element.cast<String, dynamic>();
        list.add(ExamLink.fromJson(mapWithStrings));
      }
    }
    pp('$mm getExamLinksBySubject found on local db: ${list.length}');
    return list;
  }
  Future<List<ExamDocument>> getExamDocuments() async {
    List<ExamDocument> list = [];
    List<Map<String, dynamic>> maps = await db.query(
      'exam_documents',
      columns: ["id", "title", "link"],

    );
    if (maps.isNotEmpty) {
      for (var element in maps) {
        var mapWithStrings = element.cast<String, dynamic>();
        list.add(ExamDocument.fromJson(mapWithStrings));
      }
    }
    pp('$mm getExamDocuments found on local db: ${list.length}');
    return list;
  }

  Future<List<ExamPageImage>> getExamImages(int examLinkId) async {
    List<ExamPageImage> examImages = [];
    List<Map<String, dynamic>> maps = await db.query(
      'exam_images',
      columns: ["id", "downloadUrl", "pageIndex", "bytes"],
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
