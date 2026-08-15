class CreateUserRequest {
  const CreateUserRequest({
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.location,
    required this.isActive,
  });

  final String username;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String location;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'username': username,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'confirmPassword': confirmPassword,
        'location': location,
        'isActive': isActive,
      };
}
