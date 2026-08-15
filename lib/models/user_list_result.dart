import 'app_user.dart';

class UserListResult {
  const UserListResult({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory UserListResult.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>;
    return UserListResult(
      users: (details['users'] as List)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: details['page'] as int? ?? 1,
      limit: details['limit'] as int? ?? 10,
      total: details['total'] as int? ?? 0,
      pages: details['pages'] as int? ?? 1,
    );
  }

  final List<AppUser> users;
  final int page;
  final int limit;
  final int total;
  final int pages;
}
