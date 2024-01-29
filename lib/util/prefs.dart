import 'dart:convert';

import 'package:edu_chatbot/data/org_sponsoree.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/branding.dart';
import '../data/country.dart';
import '../data/sgela_user.dart';

class Prefs {
  final SharedPreferences sharedPreferences;

  Prefs(this.sharedPreferences);

  Future saveUser(SgelaUser user) async {
    Map mJson = user.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('user', jx);
    return null;
  }

  SgelaUser? getUser() {
    var string = sharedPreferences.getString('user');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var user = SgelaUser.fromJson(jx);
    return user;
  }

  Future saveSponsoree(OrgSponsoree user) async {
    Map mJson = user.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('sponsoree', jx);
    return null;
  }

  OrgSponsoree? getSponsoree() {
    var string = sharedPreferences.getString('sponsoree');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var user = OrgSponsoree.fromJson(jx);
    return user;
  }

  void saveCountry(Country country) {
    Map mJson = country.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('country', jx);
  }

  Country? getCountry() {
    var string = sharedPreferences.getString('country');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var country = Country.fromJson(jx);
    return country;
  }

  void saveBrand(Branding brand) {
    Map mJson = brand.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('brand', jx);
  }

  Branding? getBrand() {
    var string = sharedPreferences.getString('brand');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var b = Branding.fromJson(jx);
    return b;
  }

  void saveOrganization(Organization organization) {
    Map mJson = organization.toJson();
    var jx = json.encode(mJson);
    sharedPreferences.setString('Organization', jx);
  }

  Organization? getOrganization() {
    var string = sharedPreferences.getString('Organization');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var org = Organization.fromJson(jx);
    return org;
  }

  void saveMode(int mode) {
    sharedPreferences.setInt('mode', mode);
  }

  int getMode() {
    var mode = sharedPreferences.getInt('mode');
    if (mode == null) {
      return -1;
    }
    return mode;
  }

  void saveColorIndex(int index) async {
    sharedPreferences.setInt('color', index);
    return null;
  }

  int getColorIndex() {
    var color = sharedPreferences.getInt('color');
    if (color == null) {
      return 0;
    }
    return color;
  }

  saveCountries(List<Country> countries) {
    List<Map<String, dynamic>> countryStrings =
    countries.map((pm) => pm.toJson()).toList();
    List<String> countryJsonStrings =
    countryStrings.map((pm) => json.encode(pm)).toList();
    sharedPreferences.setStringList('countries', countryJsonStrings);
  }

  List<Country> getCountries() {
    List<String>? paymentMethodJsonStrings =
    sharedPreferences.getStringList('countries');
    if (paymentMethodJsonStrings != null) {
      List<Country> paymentMethods = paymentMethodJsonStrings
          .map((pmJson) => Country.fromJson(json.decode(pmJson)))
          .toList();
      return paymentMethods;
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
  }

  List<Branding> getBrandings() {
    List<String>? brandingJsonStrings =
    sharedPreferences.getStringList('brandings');
    if (brandingJsonStrings != null) {
      List<Branding> brandings = brandingJsonStrings
          .map((pmJson) => Branding.fromJson(json.decode(pmJson)))
          .toList();
      return brandings;
    } else {
      return [];
    }
  }
//
}
