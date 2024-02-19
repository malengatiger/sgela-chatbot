import 'dart:convert';

import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/sponsoree.dart';
import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/ui/chat/ai_model_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/branding.dart';
import '../data/country.dart';
import '../data/sgela_user.dart';
import 'functions.dart';

class Prefs {
  final SharedPreferences sharedPreferences;
  static const mm = '💜💜💜💜💜Prefs 💜💜';

  Prefs(this.sharedPreferences);

  Future saveUser(SgelaUser user) async {
    Map mJson = user.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('user', jx);
    pp('$mm ... sgelaUser saved OK');
  }

  SgelaUser? getUser() {
    var string = sharedPreferences.getString('user');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var user = SgelaUser.fromJson(jx);
    pp('$mm ... sgelaUser found OK: ${user.firstName}');
    return user;
  }

  Future saveSponsoree(Sponsoree sponsoree) async {
    Map mJson = sponsoree.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('sponsoree', jx);
    pp('$mm ... sponsoree saved OK, ${sponsoree.sgelaUserName}');
  }

  Sponsoree? getSponsoree() {
    var string = sharedPreferences.getString('sponsoree');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var sponsoree = Sponsoree.fromJson(jx);
    pp('$mm ... sponsoree retrieved OK, ${sponsoree.sgelaUserName}');

    return sponsoree;
  }

  void saveCountry(Country country) {
    Map mJson = country.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('country', jx);
    pp('$mm ... country saved OK: ${country.name}');
  }

  Country? getCountry() {
    var string = sharedPreferences.getString('country');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var country = Country.fromJson(jx);
    pp('$mm ... country retrieved OK: ${country.name}');
    return country;
  }

  void saveBrand(Branding brand) {
    Map mJson = brand.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('brand', jx);
    pp('$mm ... branding saved OK: ${brand.organizationName}');
  }

  Branding? getBrand() {
    var string = sharedPreferences.getString('brand');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var b = Branding.fromJson(jx);
    pp('$mm ... branding gotten OK: ${b.organizationName}');

    return b;
  }

  void saveOrganization(Organization organization) {
    Map mJson = organization.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('Organization', jx);
    pp('$mm ... organization saved OK: ${organization.name}');
  }

  Organization? getOrganization() {
    var string = sharedPreferences.getString('Organization');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var org = Organization.fromJson(jx);
    pp('$mm ... organization retrieved OK: ${org.name}');

    return org;
  }

  void saveMode(int mode) {
    sharedPreferences.setInt('mode', mode);
  }

  int getMode() {
    var mode = sharedPreferences.getInt('mode');
    if (mode == null) {
      pp('$mm ... mode not found, returning -1');
      return -1;
    }
    return mode;
  }

  void saveColorIndex(int index) async {
    sharedPreferences.setInt('color', index);
    pp('$mm ... color index cached: $index');
    return null;
  }

  int getColorIndex() {
    var color = sharedPreferences.getInt('color');
    if (color == null) {
      pp('$mm ... return default color index 0');
      return 0;
    }
    return color;
  }

  void saveInstructionCount(int index) async {
    int c = getInstructionCount();
    sharedPreferences.setInt('instructionCount', index + c);

    pp('$mm ... color index cached: $index');
    return null;
  }

  int getInstructionCount() {
    var count = sharedPreferences.getInt('instructionCount');
    if (count == null) {
      pp('$mm ... return instructionCount = 0');
      return 0;
    }
    pp('$mm ... instructionCount: $count');
    return count;
  }

  //
  void saveGeminiHelloCount(int index) async {
    int c = getGeminiHelloCount();
    sharedPreferences.setInt('geminiHello', index + c);
    pp('$mm ... geminiHelloCount cached: $index');
    return null;
  }

  int getGeminiHelloCount() {
    var count = sharedPreferences.getInt('geminiHello');
    if (count == null) {
      pp('$mm ... return geminiHelloCount = 0');
      return 0;
    }
    pp('$mm ... geminiHelloCount: $count');
    return count;
  }

  void saveOpenAPIHelloCount() async {
    int c = getOpenAIHelloCount();
    sharedPreferences.setInt('openAPIHello', c + 1);
    pp('$mm ... geminiHelloCount cached: ${c+1}');
    return null;
  }

  int getOpenAIHelloCount() {
    var count = sharedPreferences.getInt('openAPIHello');
    if (count == null) {
      pp('$mm ... return openAPIHelloCount = 0');
      return 0;
    }
    pp('$mm ... openAPIHelloCount: $count');
    return count;
  }

  //
  void saveCurrentModel(String model) async {
    sharedPreferences.setString('aiModel', model);

    pp('$mm ... current model cached: $model');
    return null;
  }

  String getCurrentModel() {
    var model = sharedPreferences.getString('aiModel');
    if (model == null) {
      return modelGeminiAI;
    }
    pp('$mm ... model: $model');
    return model;
  }

  saveCountries(List<Country> countries) {
    List<Map<String, dynamic>> countryStrings =
        countries.map((pm) => pm.toJson()).toList();
    List<String> countryJsonStrings =
        countryStrings.map((pm) => json.encode(pm)).toList();
    sharedPreferences.setStringList('countries', countryJsonStrings);
    pp('$mm ... countries saved OK: ${countries.length}');
  }

  List<Country> getCountries() {
    List<String>? paymentMethodJsonStrings =
        sharedPreferences.getStringList('countries');
    if (paymentMethodJsonStrings != null) {
      List<Country> countries = paymentMethodJsonStrings
          .map((pmJson) => Country.fromJson(json.decode(pmJson)))
          .toList();
      pp('$mm ... countries retrieved: ${countries.length}');

      return countries;
    } else {
      return [];
    }
  }

  //
  saveBrandings(List<Branding> brandings) {
    List<Map<String, dynamic>> brandingStrings =
        brandings.map((pm) => pm.toJson()).toList();
    List<String> brandingJsonStrings =
        brandingStrings.map((pm) => json.encode(pm)).toList();
    sharedPreferences.setStringList('brandings', brandingJsonStrings);
    pp('$mm ... brandings saved OK: ${brandings.length}');
  }

  List<Branding> getBrandings() {
    List<String>? brandingJsonStrings =
        sharedPreferences.getStringList('brandings');
    if (brandingJsonStrings != null) {
      List<Branding> brandings = brandingJsonStrings
          .map((pmJson) => Branding.fromJson(json.decode(pmJson)))
          .toList();
      pp('$mm ... brandings retrieved: ${brandings.length}');

      return brandings;
    } else {
      return [];
    }
  }

  saveSubjects(List<Subject> subjects) {
    subjects.sort((a, b) => a.title!.compareTo(b.title!));
    List<Map<String, dynamic>> subjectStrings =
        subjects.map((pm) => pm.toJson()).toList();
    List<String> brandingJsonStrings =
        subjectStrings.map((pm) => json.encode(pm)).toList();
    sharedPreferences.setStringList('subjects', brandingJsonStrings);
    pp('$mm ... subjects saved OK: ${subjects.length}');
  }

  saveSubject(Subject subject) {
    List<Subject> subjects = getSubjects();
    subjects.add(subject);
    subjects.sort((a, b) => a.title!.compareTo(b.title!));
    saveSubjects(subjects);
    pp('$mm ... subject saved OK, subjects: ${subjects.length}');
  }

  List<Subject> getSubjects() {
    List<String>? subjectJsonStrings =
        sharedPreferences.getStringList('subjects');
    if (subjectJsonStrings != null) {
      List<Subject> subjects = subjectJsonStrings
          .map((pmJson) => Subject.fromJson(json.decode(pmJson)))
          .toList();
      pp('$mm ... subjects retrieved: ${subjects.length}');
      subjects.sort((a, b) => a.title!.compareTo(b.title!));
      return subjects;
    } else {
      return [];
    }
  }
//
}
