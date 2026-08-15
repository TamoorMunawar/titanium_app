class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.isActive,
    required this.role,
    required this.rawRole,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      location: json['location'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      role: json['role'] as String? ?? '',
      rawRole: json['rawRole'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? location;
  final bool isActive;
  final String role;
  final String rawRole;
  final DateTime createdAt;
  final DateTime updatedAt;
}
