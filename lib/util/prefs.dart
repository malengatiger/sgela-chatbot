import 'dart:convert';


import 'package:shared_preferences/shared_preferences.dart';

import '../data/user.dart';
import '../data/country.dart';
import 'functions.dart';

final Prefs prefs = Prefs();

class Prefs {
  Future saveUser(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map mJson = user.toJson();
    var jx = json.encode(mJson);
    prefs.setString('user', jx);
    // pp("🌽 🌽 🌽 Prefs: saveUser:  SAVED: 🌽 ${user.toJson()} 🌽 🌽 🌽");
    return null;
  }

  Future<User?> getUser() async {
    var prefs = await SharedPreferences.getInstance();
    var string = prefs.getString('user');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var user = User.fromJson(jx);
    pp("🌽 🌽 🌽 Prefs: getUser 🧩  ${user.firstName} retrieved");
    return user;
  }

  Future saveCountry(Country country) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map mJson = country.toJson();
    var jx = json.encode(mJson);
    prefs.setString('country', jx);
    pp("🌽 🌽 🌽 Prefs: saveCountry:  SAVED: 🌽 ${country.toJson()} 🌽 🌽 🌽");
    return null;
  }

  Future<Country?> getCountry() async {
    var prefs = await SharedPreferences.getInstance();
    var string = prefs.getString('country');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    var country =Country.fromJson(jx);
    pp("🌽 🌽 🌽 Prefs: getCountry 🧩  ${country.name} retrieved");
    return country;
  }

  static Future saveMode(int mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('mode', mode);
    pp("🌽🌽🌽 Prefs: saveMode: 🌽 ${mode == 1? 'DARK':'LIGHT'} 🌽🌽🌽");
    return null;
  }

  static Future<int> getMode() async {
    var prefs = await SharedPreferences.getInstance();
    var mode = prefs.getInt('mode');
    if (mode == null) {
      return -1;
    }
    pp("🌽🌽🌽 Prefs: getMode: 🌽 ${mode == 1? 'DARK':'LIGHT'} 🌽🌽🌽");
    return mode;
  }

}
