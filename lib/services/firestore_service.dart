import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_chatbot/data/exam_document.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/gemini_response_rating.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:firebase_core/firebase_core.dart';
class FirestoreService {
  final FirebaseFirestore firebaseFirestore;

  FirestoreService(this.firebaseFirestore) {
    firebaseFirestore.settings = const Settings(
      persistenceEnabled: true,
    );
  }
  Future<List<ExamDocument>> getExamDocuments() async {
    List<ExamDocument> docs = [];
    var querySnapshot =
    await firebaseFirestore.collection('ExamDocument')
        .orderBy("title").get();
    for (var s in querySnapshot.docs) {
      var doc = ExamDocument.fromJson(s.data());
      docs.add(doc);
    }
    return docs;
  }
  Future<List<Subject>> getSubjects() async {
    List<Subject> subjects = [];
    var querySnapshot =
    await firebaseFirestore.collection('Subject').orderBy("title").get();
    for (var s in querySnapshot.docs) {
      var subject = Subject.fromJson(s.data());
      subjects.add(subject);
    }
    return subjects;
  }
  Future<List<ExamLink>> getExamLinksByDocumentAndSubject({
    required int subjectId,
    required int documentId}) async {
    List<ExamLink> examLinks = await getSubjectExamLinks(subjectId);
    List<ExamLink> fList = [];

    for (var value in examLinks) {
      if (value.examDocument!.id! == documentId) {
        fList.add(value);
      }
    }
    return fList;
  }
  Future<List<ExamLink>> getSubjectExamLinks(int subjectId) async {
    List<ExamLink> examLinks = [];
    var querySnapshot =
    await firebaseFirestore.collection('ExamLink')
        .where('subject.id', isEqualTo: subjectId)
        .get();
    for (var s in querySnapshot.docs) {
      var subject = ExamLink.fromJson(s.data());
      examLinks.add(subject);
    }
    return examLinks;

  }
  Future<List<GeminiResponseRating>> getRatings(int examLinkId) async {
    List<GeminiResponseRating> ratings = [];
    var querySnapshot =
    await firebaseFirestore.collection('GeminiResponseRating')
        .where('examLinkId', isEqualTo: examLinkId)
        .get();
    for (var s in querySnapshot.docs) {
      var rating = GeminiResponseRating.fromJson(s.data());
      ratings.add(rating);
    }
    return ratings;
  }
  Future addRating(GeminiResponseRating rating) async {
    var colRef = firebaseFirestore.collection('GeminiResponseRating');
    await colRef.add(rating.toJson());
  }
}
