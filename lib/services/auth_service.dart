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

  Future<SgelaUser?> registerUser(SgelaUser user) async {
    pp('$mm create Firebase User ...');

    try {
      var creds = await firebaseAuth.createUserWithEmailAndPassword(
              email: user.email!, password: 'pass123');
      if (creds.user != null) {
            user.firebaseUserId = creds.user?.uid;
            await firebaseAuth.currentUser!
                .updateDisplayName('${user.firstName} ${user.lastName}');
            var sgelaUser = await firestoreService.addSgelaUser(user);
            prefs.saveUser(sgelaUser);
            pp('$mm User added to Firebase/Firestore, saved in prefs: ${sgelaUser.toJson()}');
            return sgelaUser;
          }
    } catch (e,s) {
      pp(e);
      pp(s);
      throw Exception('Unable to create authenticated user. Check your email address');
    }
    return null;
  }

  Future forgotPassword(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<SgelaUser?> signInUser(String email, String password) async {
    pp('$mm create Firebase User ...');

    var creds = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    if (creds.user == null) {
      throw Exception('Sign in failed');
    }
    var u = await firestoreService.getSgelaUser(creds.user!.uid);

    if (u != null) {
      var b = await firestoreService.getSponsoree(creds.user!.uid);
      pp('$mm User signed in: ${u.toJson()}');
      if ((b != null)) {
        pp('$mm Sponsoree is: ${b.toJson()}');
      }

      return u;
    }

    return null;
  }
}
