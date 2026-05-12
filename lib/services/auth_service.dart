// A collection of functions that communicate with login_page, register_page, and
// profile_page to handle most of the database logic on behalf of those files.

// Uses Flutter Mapp's example file as a starting point.
// https://youtu.be/pioTvtt3O3I?si=fd1S52sr82R79U2q 

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email, password: password);
  }

  Future<String?> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
      );
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
          'uid': userCredential.user!.uid, // EVERY user has a unique UID
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
          // Everything below is NOT required during registration!
<<<<<<< HEAD
          'phone': null, // Add ability to add # to an eventual profile editor 
          'myInstructor': null,
=======
          'phone': null,
          'myInstructors': [],
>>>>>>> purple-auth-service-feature-branch
          'problems': [],
          'assignedSheets': [],
          'completedSheets': [],
          // TODO: Add Google account field
          // TODO: Add Facebook account field
        });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

<<<<<<< HEAD
=======
  Future<String?> editProfile({
    required String oldEmail,
    required String newEmail,
    required String firstName,
    required String lastName,
    required String role,
    required String phone,
  }) async {
    try {
      if (newEmail != oldEmail) {
        await FirebaseAuth.instance.currentUser!.verifyBeforeUpdateEmail(newEmail);
      }
      await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({
          'email': newEmail,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
          'phone': phone,
        });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePassword({
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

>>>>>>> purple-auth-service-feature-branch
  // TODO: Create new function to handle login with Google account

  // TODO: Create new function to handle login with Facebook account

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<bool> doesEmailExist(String email) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .get();
    return snapshot.docs.isNotEmpty;
  }

<<<<<<< HEAD
=======
  Future<bool> doesPhoneExist(String phone) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('phone', isEqualTo: phone)
      .get();
    return snapshot.docs.isNotEmpty;
  }

>>>>>>> purple-auth-service-feature-branch
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

<<<<<<< HEAD
=======
  Future<void> updateEmail({
    required String email,
  }) async {
    await firebaseAuth.currentUser!.verifyBeforeUpdateEmail(email);
  }

  Future<String?> verifyPhone({
    required String phone,
    }) async {
      try {
        // final RecaptchaVerifier verifier = RecaptchaVerifier(
        //   auth: FirebaseAuthPlatform.instance,
        // );

        await firebaseAuth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await firebaseAuth.currentUser?.linkWithCredential(credential);
          }, 
          verificationFailed: (FirebaseAuthException e) {
            print('Auth Error Code: ${e.code}');
            print('Auth Error Message: ${e.message}');
          }, 
          codeSent: (String verificationId, int? resendToken) async {
            String smsCode = 'xxxx';
            PhoneAuthCredential credential = PhoneAuthProvider.credential(
              verificationId: verificationId, 
              smsCode: smsCode
            );
            await firebaseAuth.signInWithCredential(credential);
          }, 
          timeout: const Duration(seconds: 60),
          codeAutoRetrievalTimeout: (String verificationId) {
          },
        );
      } catch (e) {
        print('');
      }
      return null;
    }

  Future<void> deleteAccount({
    required User? user,
  }) async {
    // Delete user from Firestore
    await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser?.uid)
      .delete();

    // Delete user from Firebase
    await user?.delete();
    signOut();
  }
>>>>>>> purple-auth-service-feature-branch


  // Everything below is other functions from Flutter Mapp. We can either use them
  // later, or delete them if we don't need them.

  // Future<void> resetPassword({
  //   required String email,
  // }) async {
  //   await firebaseAuth.sendPasswordResetEmail(email: email);
  // }

  // Future<void> updateUsername({
  //   required String username,
  // }) async {
  //   await currentUser!.updateDisplayName(username);
  // }

  // Future<void> deleteAccount({
  //   required String email,
  //   required String password,
  // }) async {
  //   AuthCredential credential = 
  //     EmailAuthProvider.credential(email: email, password: password);
  //   await currentUser!.reauthenticateWithCredential(credential);
  //   await currentUser!.delete();
  //   await firebaseAuth.signOut();
  // }

  // Future<void> resetPasswordFromCurrentPassword({
  //   required String currentPassword,
  //   required String newPassword,
  //   required String email,
  // }) async {
<<<<<<< HEAD
  //   AuthCredential credential = 
  //     EmailAuthProvider.credential(email: email, password: currentPassword);
  //   await currentUser!.reauthenticateWithCredential(credential);
  //   await currentUser!.updatePassword(newPassword);
=======
    // AuthCredential credential = 
    //   EmailAuthProvider.credential(email: email, password: currentPassword);
    // await currentUser!.reauthenticateWithCredential(credential);
    // await currentUser!.updatePassword(newPassword);
>>>>>>> purple-auth-service-feature-branch
  // }
}