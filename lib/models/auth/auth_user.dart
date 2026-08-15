class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.usertype,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      usertype: json['usertype'] as String? ?? '',
    );
  }

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String usertype;

  String get fullName => '$firstName $lastName'.trim();

  bool get isSuperAdmin => usertype == 'superadmin';

  bool get isGuest => usertype == 'guest';

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'usertype': usertype,
      };
}
