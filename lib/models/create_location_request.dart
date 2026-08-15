class CreateLocationRequest {
  const CreateLocationRequest({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
