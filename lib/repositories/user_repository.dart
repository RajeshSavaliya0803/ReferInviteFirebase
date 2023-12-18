// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/code_generator.dart';
import '../services/deep_link_service.dart';

class Userrepository {
  Userrepository._();
  static Userrepository? _instance;

  static Userrepository get instance {
    _instance ??= Userrepository._();
    return _instance!;
  }

  ValueNotifier<User> currentUserNotifier = ValueNotifier<User>(User.empty());

  User? get user {
    return currentUserNotifier.value;
  }

  listenToCurrentUser(String uid) {
    final snapshot =
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    snapshot.listen((event) {
      final user = User.fromJson(event.data() as Map<String, dynamic>);
      currentUserNotifier.value = user;
      notifyListenersUser();
    });
  }

  Future<User?> login(String email, String password) async {
    final authUser = await AuthService.instance?.login(email, password);
    if (authUser != null) {
      final user = await getuser(authUser.uid);
      currentUserNotifier.value = user;
      notifyListenersUser();
      listenToCurrentUser(user.uid);
      return user;
    } else {
      return null;
    }
  }

  Future<User?> registeruser(String name, String email, String password,
      {String referrerCode = ''}) async {
    final uid = await AuthService.instance?.signup(email, password);
    final referCode = CodeGenerator.generatecode('refer');

    final referLink = await DeepLinkService.instance
        ?.createReferlink(referCode, referrerCode);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'uid': uid,
      'refer_link': referLink,
      'refer_code': referCode,
      "referral_code": referrerCode,
      'reward': 0,
    });

    print('object----->${referrerCode}');

    currentUserNotifier.value = await getuser(uid!);
    listenToCurrentUser(uid);
    notifyListenersUser();

    if (referrerCode.isNotEmpty) {
      await rewarduser(uid, referrerCode);
    }
  }

  Future<User> getuser(String uid) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    debugPrint("user Id ${userSnapshot.data()}");
    if (userSnapshot.exists) {
      return User.fromJson(userSnapshot.data() as Map<String, dynamic>);
    } else {
      return User.empty();
    }
  }

  Future<User> getreferreruser(String referCode) async {
    final docSnapshots = await FirebaseFirestore.instance
        .collection('users')
        .where('refer_code', isEqualTo: referCode)
        .get();

    final userSnapshot = docSnapshots.docs.first;

    if (userSnapshot.exists) {
      return User.fromJson(userSnapshot.data());
    } else {
      return User.empty();
    }
  }

  Future<void> rewarduser(String currentUserUID, String referrerCode) async {
    try {
      final referer = await getreferreruser(referrerCode);
      print('------->>>>$referer');

      final checkIfUserAlreadyExist = await FirebaseFirestore.instance
          .collection('users')
          .doc(referer.uid)
          .collection('referrers')
          .doc(currentUserUID)
          .get();

      if (!checkIfUserAlreadyExist.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(referer.uid)
            .collection('referrers')
            .doc(currentUserUID)
            .set({
          "uid": currentUserUID,
          "createdAt": DateTime.now().toUtc().millisecondsSinceEpoch,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(referer.uid)
            .update({
          "reward": FieldValue.increment(100),
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> listenTocurrentAuth() async {
    if (Userrepository.instance.user == null) {
      var fbUser = auth.FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        try {
          fbUser = await auth.FirebaseAuth.instance.authStateChanges().first;
          if (fbUser != null) {
            currentUserNotifier.value = await getuser(fbUser.uid);
            notifyListenersUser();
          }
        } catch (_) {}
      }
      if (fbUser == null) {
        debugPrint("no  user");
      } else {
        final user = await getuser(fbUser.uid);
        currentUserNotifier.value = user;
        debugPrint(user.uid);
        listenToCurrentUser(user.uid);
        notifyListenersUser();
      }
    }
  }

  notifyListenersUser() {
    currentUserNotifier.notifyListeners();
  }

  logoutUser() async {
    currentUserNotifier.value = User.empty();
    notifyListenersUser();
    await AuthService.instance?.logOut();
  }
}
