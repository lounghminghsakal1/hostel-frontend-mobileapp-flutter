import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] for the values the app
/// needs to persist locally: the auth token and the signed-in role.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _authTokenKey = 'auth_token';
  static const _userRoleKey = 'user_role';

  Future<void> saveAuthToken(String token) => _storage.write(key: _authTokenKey, value: token);

  Future<String?> getAuthToken() => _storage.read(key: _authTokenKey);

  Future<void> saveUserRole(String role) => _storage.write(key: _userRoleKey, value: role);

  Future<String?> getUserRole() => _storage.read(key: _userRoleKey);

  Future<void> clearSession() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _userRoleKey);
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});
