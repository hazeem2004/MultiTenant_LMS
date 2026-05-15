import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../domain/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _currentRole = 'instructor';
  static void setRole(String role) => _currentRole = role;

  Future<AppUser?> signInWithGitHub() async {
    try {
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      
      final UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(githubProvider);
      } else {
        credential = await _auth.signInWithProvider(githubProvider);
      }
      
      if (credential.user != null) {
        final user = credential.user!;
        
        // Sync with Firestore
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDocRef.get();
        
        String role = 'instructor'; // Default role for GitHub login
        
        if (!docSnapshot.exists) {
          await userDocRef.set({
            'email': user.email ?? '',
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          role = docSnapshot.data()?['role'] as String? ?? 'instructor';
        }
        
        return AppUser(
          uid: user.uid,
          email: user.email ?? '',
          role: role,
        );
      }
      return null;
    } catch (e) {
      print('GitHub Sign-In Error: $e');
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
      final role = doc.data()?['role'] as String? ?? 'student';
      
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        role: role,
      );
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
