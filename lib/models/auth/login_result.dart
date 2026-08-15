import 'auth_user.dart';

class LoginResult {
  const LoginResult({required this.user, required this.token});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>;
    return LoginResult(
      user: AuthUser.fromJson(details['user'] as Map<String, dynamic>),
      token: details['token'] as String,
    );
  }

  final AuthUser user;
  final String token;
}
