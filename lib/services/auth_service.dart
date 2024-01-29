import 'package:edu_chatbot/data/sgela_user.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../util/prefs.dart';
import 'firestore_service.dart';

class AuthService {
  static const String mm = '🍎🍎🍎 AuthService: ';

  final FirebaseAuth firebaseAuth;
  final Prefs prefs;
  final FirestoreService firestoreService;

  AuthService(this.firebaseAuth, this.prefs, this.firestoreService);
  Future registerUser(SgelaUser user) async {
    pp('$mm create Firebase User ...');

    var creds = await firebaseAuth.createUserWithEmailAndPassword(
        email: user.email!, password: 'pass123');
    user.firebaseUserId = creds.user?.uid;
    prefs.saveUser(user);
    await firestoreService.addSgelaUser(user);

    pp('$mm User added to database, saved in prefs: ${user.toJson()}');

  }
}
