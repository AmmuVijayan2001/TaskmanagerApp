import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/error/app_exception.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) await _ensureProfile(user);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_authMessage(error), cause: error);
    } on FirebaseException catch (error) {
      throw ServerException(
        'Your profile could not be loaded. Please try again.',
        cause: error,
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null)
        throw const AuthException('Your account could not be created.');

      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'themeMode': 'system',
      });
    } on FirebaseAuthException catch (error) {
      throw AuthException(_authMessage(error), cause: error);
    } on FirebaseException catch (error) {
      throw ServerException(
        'Your account was created, but your profile could not be saved.',
        cause: error,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        'Could not sign out. Please try again.',
        cause: error,
      );
    }
  }

  Stream<UserProfile?> watchProfile(String uid) =>
      _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data == null) return null;
        final timestamp = data['createdAt'] as Timestamp?;
        return UserProfile(
          id: snapshot.id,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          createdAt: timestamp?.toDate() ?? DateTime.now(),
          themeMode: data['themeMode'] as String? ?? 'system',
        );
      });

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.id).update({
        'name': profile.name,
        'themeMode': profile.themeMode,
      });
    } on FirebaseException catch (error) {
      throw ServerException(
        'Your profile could not be saved. Please try again.',
        cause: error,
      );
    }
  }

  Future<void> _ensureProfile(User user) async {
    final reference = _firestore.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    if (snapshot.exists) return;

    await reference.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'themeMode': 'system',
    });
  }

  String _authMessage(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-not-found' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'wrong-password' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account already exists with this email.',
    'weak-password' => 'Choose a password with at least 6 characters.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'network-request-failed' => 'Check your internet connection and try again.',
    _ => 'Authentication failed. Please try again.',
  };
}
