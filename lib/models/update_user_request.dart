class UpdateUserRequest {
  const UpdateUserRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.location,
    required this.isActive,
  });

  final String fullName;
  final String phoneNumber;
  final String location;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'location': location,
        'isActive': isActive,
      };
}
