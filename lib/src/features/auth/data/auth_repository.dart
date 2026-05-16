import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../domain/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final uid = credential.user!.uid;
        
        // Ensure admin@demo.com is always approved
        if (email == 'admin@demo.com') {
          await _firestore.collection('users').doc(uid).set({
            'email': email,
            'role': 'ADMIN',
            'isApproved': true,
          }, SetOptions(merge: true));
        }

        final doc = await _firestore.collection('users').doc(uid).get();
        return AppUser.fromMap(uid, doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Sign-In Error: $e');
      rethrow;
    }
  }

  Future<AppUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final user = credential.user!;
        
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'role': role,
          'isApproved': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return AppUser(
          uid: user.uid,
          email: email,
          role: role,
          isApproved: false,
        );
      }
      return null;
    } catch (e) {
      print('Register Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return AppUser.fromMap(user.uid, doc.data() ?? {});
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
