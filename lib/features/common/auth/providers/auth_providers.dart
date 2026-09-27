import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../student/home/providers/student_home_providers.dart';
import '../data/auth_repository.dart';
import '../model/user_role.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

/// Holds the signed-in role once login succeeds, and the loading/error
/// state of the login request itself. `null` data means signed out.
class AuthController extends AsyncNotifier<UserRole?> {
  @override
  Future<UserRole?> build() async {
    final storedRole = await ref.read(secureStorageProvider).getUserRole();
    return storedRole == null ? null : UserRole.fromStorageValue(storedRole);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );

      final storage = ref.read(secureStorageProvider);
      await storage.saveAuthToken(result.token);
      await storage.saveUserRole(result.role.storageValue);

      return result.role;
    });
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearSession();
    // Kept alive app-wide, so drop it to avoid showing the previous user's
    // data after the next sign-in.
    ref.invalidate(studentHomeProvider);
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserRole?>(
  AuthController.new,
);
