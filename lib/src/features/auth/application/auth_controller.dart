import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';
import '../data/auth_repository.dart';

class AuthController extends StreamNotifier<AppUser?> {
  @override
  Stream<AppUser?> build() {
    return ref.watch(authRepositoryProvider).authStateChanges();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return await repo.signInWithEmailAndPassword(email, password);
    });
  }

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return await repo.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return null;
    });
  }
}

final authControllerProvider = StreamNotifierProvider<AuthController, AppUser?>(() {
  return AuthController();
});
