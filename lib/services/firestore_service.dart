import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_chatbot/data/exam_document.dart';
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/exam_page_content.dart';
import 'package:edu_chatbot/data/gemini_response_rating.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/sponsoree.dart';
import 'package:edu_chatbot/data/sponsoree_activity.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/data/tokens_used.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/file_downloader_widget.dart';
import 'package:edu_chatbot/util/image_file_util.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geocoding/geocoding.dart';

import '../data/branding.dart';
import '../data/city.dart';
import '../data/country.dart';
import '../data/sgela_user.dart';
import '../firebase_options.dart';
import '../util/environment.dart';
import '../util/functions.dart';
import '../util/location_util.dart';

class FirestoreService {
  final Prefs prefs;
  final ColorWatcher colorWatcher;

  static const mm = ' 🥦🥦🥦FirestoreService 🥦 ';
  final FirebaseFirestore firebaseFirestore;
  final LocalDataService localDataService;

  FirestoreService(this.prefs, this.colorWatcher, this.firebaseFirestore,
      this.localDataService) {
    pp('$mm ... FirestoreService constructor ...');
    init();
  }

  init() async {
    var app = await Firebase.initializeApp(
      name: ChatbotEnvironment.getFirebaseName(),
      options: DefaultFirebaseOptions.currentPlatform,
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

  Future<List<ExamPageContent>> getExamPageContents(int examLinkId) async {
    List<ExamPageContent> examPageContents =
        await localDataService.getExamPageContents(examLinkId);
    if (examPageContents.isNotEmpty) {
      return examPageContents;
    }
    var start = DateTime.now();
    var querySnapshot = await firebaseFirestore
        .collection('ExamPageContent')
        .where('examLinkId', isEqualTo: examLinkId)
        .get();

    for (var snapshot in querySnapshot.docs) {
      var content = ExamPageContent.fromJson(snapshot.data());
      examPageContents.add(content);
    }
    pp('$mm ... examPageContents: ${examPageContents.length} ... '
        'will download the page images ......... ');
      for (var value in examPageContents) {
        if (value.pageImageUrl != null) {
          File file = await ImageFileUtil.downloadFile(
              value.pageImageUrl!, 'file${value.pageIndex!}.png');
          value.uBytes = file.readAsBytesSync();
        }
        await localDataService.addExamPageContent(value);
      }

    var end = DateTime.now();
    pp('$mm Files downloaded: elapsed time: ${end.difference(start).inSeconds} seconds');
    return examPageContents;
  }

  List<City> cities = [];

  Future<List<City>> getCountryCities(int countryId) async {
    if (cities.isNotEmpty) {
      return cities;
    }

    var querySnapshot = await firebaseFirestore
        .collection('City')
        .where('countryId', isEqualTo: countryId)
        .get();
    for (var s in querySnapshot.docs) {
      var subject = City.fromJson(s.data());
      cities.add(subject);
    }
    return cities;
  }

  Future<List<AIResponseRating>> getRatings(int examLinkId) async {
    List<AIResponseRating> ratings = [];
    var querySnapshot = await firebaseFirestore
        .collection('GeminiResponseRating')
        .where('examLinkId', isEqualTo: examLinkId)
        .get();
    for (var s in querySnapshot.docs) {
      var rating = AIResponseRating.fromJson(s.data());
      ratings.add(rating);
    }
    return ratings;
  }

  Future addRating(AIResponseRating rating) async {
    var colRef = firebaseFirestore.collection('AIResponseRating');
    await colRef.add(rating.toJson());
  }

  Future addTokensUsed(TokensUsed tokensUsed) async {
    var colRef = firebaseFirestore.collection(
        'TokensUsed');
    await colRef.add(tokensUsed.toJson());
    pp('$mm ... tokensUsed added to database: ${tokensUsed.toJson()}');
  }

  Future addOrgSponsoree(Sponsoree sponsoree) async {
    var colRef = firebaseFirestore.collection('Sponsoree');
    pp('$mm ... adding sponsoree, check sgelaUser: ${sponsoree.toJson()}');
    var res = await colRef.add(sponsoree.toJson());
    prefs.saveSponsoree(sponsoree);
    pp('$mm ... res path: ${res.path}');
  }

  Future addSponsoreeActivity(SponsoreeActivity sponsoreeActivity) async {
    var colRef = firebaseFirestore.collection('SponsoreeActivity');
    pp('$mm ... adding addSponsoreeActivity, check sponsoree: ${sponsoreeActivity.toJson()}');
    var res = await colRef.add(sponsoreeActivity.toJson());
    pp('$mm ... addSponsoreeActivity done; path: ${res.path}');
  }

  Future<List<SponsoreeActivity>> getSponsoreeActivity(
      int organizationId) async {
    var querySnapshot = await firebaseFirestore
        .collection('SponsoreeActivity')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('date', descending: true)
        .get();

    List<SponsoreeActivity> activities = [];
    for (var s in querySnapshot.docs) {
      var activity = SponsoreeActivity.fromJson(s.data());
      activities.add(activity);
    }
    return activities;
  }

  Future<List<SponsoreeActivity>> getSponsoreeActivityByDate(
      int organizationId, String date) async {
    var querySnapshot = await firebaseFirestore
        .collection('SponsoreeActivity')
        .where('organizationId', isEqualTo: organizationId)
        .where('date', isGreaterThanOrEqualTo: date)
        .orderBy('date', descending: true)
        .get();

    List<SponsoreeActivity> activities = [];
    for (var s in querySnapshot.docs) {
      var activity = SponsoreeActivity.fromJson(s.data());
      activities.add(activity);
    }
    return activities;
  }

  Future<SgelaUser> addSgelaUser(SgelaUser user) async {
    var ref =
        await firebaseFirestore.collection('SgelaUser').add(user.toJson());
    var m = ref.path;
    prefs.saveUser(user);
    pp('$mm user added to database and local prefs: ${user.toJson()}');
    return user;
  }

  Future<Country?> getLocalCountry() async {
    if (localCountry != null) {
      return localCountry!;
    }
    if (countries.isEmpty) {
      await getCountries();
    }
    var place = await LocationUtil.findNearestPlace(
        'getLocalCountry in FirestoreService');
    if (place != null) {
      for (var country in countries) {
        if (country.name!.contains(place.country!)) {
          localCountry = country;
          pp('$mm ... local country found: ${localCountry!.name}');
          break;
        }
      }
    }
    if (localCountry != null && place != null) {
      pp('$mm ... finding local city ........');
      _localCity = await _getLocalCity(localCountry!.id!, place);
    }
    return localCountry;
  }

  City? _localCity;

  Future<City?> _getLocalCity(int countryId, Placemark place) async {
    if (cities.isEmpty) {
      pp('$mm ... getting country cities');
      cities = await getCities(countryId);
    }

    pp('_getLocalCity looking for city: ${place.toJson()} in ${cities.length} cities');

    for (var city in cities) {
      pp('$mm checking city: ${city.name}');
      if (place.locality != null) {
        if (city.name!.contains(place.locality!)) {
          _localCity = city;
          break;
        }
      }

      if (place.subLocality != null) {
        if (city.name!.contains(place.subLocality!)) {
          _localCity = city;
          break;
        }
      }
      if (place.administrativeArea != null) {
        if (city.name!.contains(place.administrativeArea!)) {
          _localCity = city;
          break;
        }
      }
      if (place.subAdministrativeArea != null) {
        if (city.name!.contains(place.subAdministrativeArea!)) {
          _localCity = city;
          break;
        }
      }
    }
    pp('$mm ... local city found: 🍎🍎 ${_localCity?.name} 🍎🍎');

    return _localCity;
  }

  City? get city => _localCity;
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

  Future<SgelaUser?> getSgelaUser(String firebaseUserId) async {
    pp('$mm ... getSgelaUser from Firestore ... firebaseUserId: $firebaseUserId');
    List<SgelaUser> list = [];
    var qs = await firebaseFirestore
        .collection('SgelaUser')
        .where('firebaseUserId', isEqualTo: firebaseUserId)
        .get();
    for (var snap in qs.docs) {
      list.add(SgelaUser.fromJson(snap.data()));
    }
    pp('$mm ... users found: ${list.length}');

    if (list.isNotEmpty) {
      prefs.saveUser(list.first);
      return list.first;
    }
    return null;
  }

  Future<Sponsoree?> getSponsoree(String firebaseUserId) async {
    pp('$mm ... getSponsoree from Firestore ... firebaseUserId: $firebaseUserId');
    List<Sponsoree> list = [];

    var qs = await firebaseFirestore
        .collection('Sponsoree')
        .where('sgelaFirebaseId', isEqualTo: firebaseUserId)
        .get();

    for (var snap in qs.docs) {
      list.add(Sponsoree.fromJson(snap.data()));
    }
    pp('$mm ... sponsorees found: ${list.length}');

    if (list.isNotEmpty) {
      prefs.saveSponsoree(list.first);
      return list.first;
    }
    return null;
  }

  Future<List<City>> getCities(int countryId) async {
    pp('$mm ... get cities from Firestore ... countryId: $countryId');
    var qs = await firebaseFirestore
        .collection('City')
        .where('countryId', isEqualTo: countryId)
        .get();
    pp('$mm ... getCities found: ${qs.size} cities');

    cities.clear();
    for (var snap in qs.docs) {
      cities.add(City.fromJson(snap.data()));
    }

    pp('$mm ... cities found: ${cities.length}');
    return cities;
  }

  List<Branding> brandings = [];

  Future<List<Branding>> getOrganizationBrandings(
      int organizationId, bool refresh) async {
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
      prefs.saveBrand(brandings.first);
      if (brandings.first.colorIndex == null) {
        prefs.saveColorIndex(7);
        colorWatcher.setColor(7);
      } else {
        prefs.saveColorIndex(brandings.first.colorIndex!);
        colorWatcher.setColor(brandings.first.colorIndex!);
      }
      return brandings;
    }

    brandings = prefs.getBrandings();
    return brandings;
  }
//
}

class UrlBag {
  late int pageIndex;
  late String url;

  UrlBag(this.pageIndex, this.url);
}
