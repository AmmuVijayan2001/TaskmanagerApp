import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref
      .watch(authStateProvider)
      .when(data: (user) => user, loading: () => null, error: (_, __) => null);
  if (user == null) return const Stream.empty();
  return ref.watch(authRepositoryProvider).watchProfile(user.uid);
});

final appThemeModeProvider = Provider<ThemeMode>(
  (ref) => ref
      .watch(userProfileProvider)
      .when(
        data: (profile) => switch (profile?.themeMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        loading: () => ThemeMode.system,
        error: (_, __) => ThemeMode.system,
      ),
);

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}
  Future<void> save(UserProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).updateProfile(profile),
    );
    if (state.hasError) throw state.error!;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signIn(email: email, password: password),
    );
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.register(name: name, email: email, password: password),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.signOut);
  }
}
