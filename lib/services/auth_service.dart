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
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
          'problems': null,  // Problems are created after registration 
        });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Everything below is other functions from Flutter Mapp. We can either use them
  // later, or delete them if we don't need them.


  // Future<void> signOut() async {
  //   await firebaseAuth.signOut();
  // }

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
  //   AuthCredential credential = 
  //     EmailAuthProvider.credential(email: email, password: currentPassword);
  //   await currentUser!.reauthenticateWithCredential(credential);
  //   await currentUser!.updatePassword(newPassword);
  // }
}