import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';
import '../data/auth_repository.dart';

class AuthController extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    // Initial state is null (no user logged in)
    return const AsyncData(null);
  }

  Future<void> signInWithGitHub() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.signInWithGitHub();
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      ref.read(authRepositoryProvider).signOut();
      return null;
    });
  }
}

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<AppUser?>>(() {
  return AuthController();
});
