import 'user_role.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.token,
    required this.role,
    required this.email,
  });

  final String token;
  final UserRole role;
  final String email;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    return LoginResponseModel(
      token: data['token'] as String,
      role: UserRole.fromStorageValue(user['role'] as String?),
      email: user['email'] as String? ?? '',
    );
  }
}
