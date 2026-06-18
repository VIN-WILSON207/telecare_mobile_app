import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Provides the singleton [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the singleton [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides the [AuthRepository], injecting Firebase instances.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// The main auth state provider.
///
/// Widgets should `ref.watch(authNotifierProvider)` to react to auth changes
/// and `ref.read(authNotifierProvider.notifier)` to trigger actions.
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience stream provider that exposes Firebase Auth state changes.
///
/// Useful for the router redirect guard.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});
