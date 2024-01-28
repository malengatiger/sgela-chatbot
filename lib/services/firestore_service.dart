import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_chatbot/data/exam_document.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/gemini_response_rating.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/branding.dart';
import '../data/city.dart';
import '../data/country.dart';
import '../data/user.dart';
import '../util/functions.dart';
import '../util/location_util.dart';

class FirestoreService {
  final FirebaseFirestore firebaseFirestore;

  final Prefs prefs;
  static const mm = ' 🥦🥦🥦FirestoreService';

  FirestoreService(this.firebaseFirestore, this.prefs) {
    firebaseFirestore.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  Future<List<ExamDocument>> getExamDocuments() async {
    List<ExamDocument> docs = [];
    var querySnapshot = await firebaseFirestore
        .collection('ExamDocument')
        .orderBy("title")
        .get();
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

  Future<List<ExamLink>> getExamLinksByDocumentAndSubject(
      {required int subjectId, required int documentId}) async {
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
    var querySnapshot = await firebaseFirestore
        .collection('ExamLink')
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
    var querySnapshot = await firebaseFirestore
        .collection('GeminiResponseRating')
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

  Future<User> addUser(User user) async {
    var ref = await firebaseFirestore.collection('User').add(user.toJson());
    var m = ref.path;
    pp('$mm user added to database: ${user.toJson()}');
    return user;
  }

  List<Country> countries = [];

  Future<List<Country>> getCountries() async {
    countries = prefs.getCountries();
    if (countries.isNotEmpty) {
      return countries;
    }
    countries.clear();
    pp('$mm ... get countries from Firestore ...');

    var qs = await firebaseFirestore.collection('Country').get();
    for (var snap in qs.docs) {
      countries.add(Country.fromJson(snap.data()));
    }
    pp('$mm ... countries found in Firestore: ${countries.length}');
    prefs.saveCountries(countries);
    getLocalCountry();
    return countries;
  }

  List<Organization> organizations = [];
  Future<List<Organization>> getOrganizations() async {

    pp('$mm ... get Organizations from Firestore ...');

    var qs = await firebaseFirestore.collection('Organization').get();
    for (var snap in qs.docs) {
      organizations.add(Organization.fromJson(snap.data()));
    }
    pp('$mm ... organizations found in Firestore: ${organizations.length}');
    return organizations;
  }
  Future<List<Branding>> getAllBrandings() async {

    pp('$mm ... get getAllBrandings from Firestore ...');

    var qs = await firebaseFirestore.collection('Branding').get();
    for (var snap in qs.docs) {
      brandings.add(Branding.fromJson(snap.data()));
    }
    pp('$mm ... brandings found in Firestore: ${brandings.length}');
    return brandings;
  }
  Country? localCountry;
  Future<Country?> getLocalCountry() async {
    if (localCountry != null) {
      return localCountry!;
    }
    if (countries.isEmpty) {
      await getCountries();
    }
    var place = await LocationUtil.findNearestPlace();
    if (place != null) {
      for (var value in countries) {
        if (value.name!.contains(place.country!)) {
          localCountry = value;
          pp('$mm ... local country found: ${localCountry!.name}');
          break;
        }
      }
    }
    return localCountry;
  }

  Future<Organization?> getOrganization(int organizationId) async {
    pp('$mm ... getOrganization from Firestore ... organizationId: $organizationId');
    List<Organization> list = [];
    var qs = await firebaseFirestore
        .collection('Organization')
        .where('id', isEqualTo: organizationId)
        .get();
    for (var snap in qs.docs) {
      list.add(Organization.fromJson(snap.data()));
    }
    pp('$mm ... orgs found: ${list.length}');

    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  Future<List<City>> getCities(int countryId) async {
    pp('$mm ... get cities from Firestore ... countryId: $countryId');
    List<City> cities = [];
    var qs = await firebaseFirestore
        .collection('City')
        .where('countryId', isEqualTo: countryId)
        .get();
    pp('$mm ... qs found: ${qs.size} cities');

    for (var snap in qs.docs) {
      cities.add(City.fromJson(snap.data()));
    }

    pp('$mm ... cities found: ${cities.length}');
    return cities;
  }

  List<Branding> brandings = [];
  Future<List<Branding>> getOrganizationBrandings(int organizationId, bool refresh) async {
    if (refresh) {
      pp('$mm ... get branding from Firestore ... organizationId: $organizationId');
      var qs = await firebaseFirestore
          .collection('Branding')
          .where('organizationId', isEqualTo: organizationId)
          .get();
      brandings.clear();
      for (var snap in qs.docs) {
        brandings.add(Branding.fromJson(snap.data()));
      }
      pp('$mm ... brandings found: ${brandings.length}');
      brandings.sort((a, b) => b.date!.compareTo(a.date!));
      prefs.saveBrandings(brandings);
      return brandings;
    }

    brandings = prefs.getBrandings();
    return brandings;
  }
}
