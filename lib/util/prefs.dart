import 'dart:convert';

import 'package:edu_chatbot/data/sponsoree.dart';
import 'package:edu_chatbot/data/organization.dart';
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
    pp('$mm ... mode saved OK: $mode');

  }

  int getMode() {
    var mode = sharedPreferences.getInt('mode');
    if (mode == null) {
      pp('$mm ... mode not found, returning -1');
      return -1;
    }
    pp('$mm ... mode saved OK: $mode');
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
    pp('$mm ... color index: $color');
    return color;
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
//
}
