import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/create_user_request.dart';
import '../models/update_user_request.dart';
import '../repositories/user_repository.dart';
import 'auth_controller.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});

class UsersPageState {
  const UsersPageState({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  final List<AppUser> users;
  final int page;
  final int limit;
  final int total;
  final int pages;
}

class UserController extends AsyncNotifier<UsersPageState> {
  static const _pageSize = 10;

  @override
  Future<UsersPageState> build() => _fetch(page: 1);

  Future<UsersPageState> _fetch({required int page}) async {
    final result = await ref
        .read(userRepositoryProvider)
        .listUsers(page: page, limit: _pageSize);
    return UsersPageState(
      users: result.users,
      page: result.page,
      limit: result.limit,
      total: result.total,
      pages: result.pages,
    );
  }

  Future<void> goToPage(int page) async {
    final current = state.value;
    if (current != null && current.page == page) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(page: page));
  }

  Future<void> refresh() async {
    final page = state.value?.page ?? 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(page: page));
  }

  Future<AppUser> createUser(CreateUserRequest request) async {
    final newUser = await ref.read(userRepositoryProvider).createUser(request);

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        UsersPageState(
          users: [newUser, ...current.users],
          page: current.page,
          limit: current.limit,
          total: current.total + 1,
          pages: current.pages,
        ),
      );
    }
    return newUser;
  }

  Future<AppUser> updateUser(String id, UpdateUserRequest request) async {
    final updated = await ref.read(userRepositoryProvider).updateUser(id, request);

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        UsersPageState(
          users: [
            for (final u in current.users) u.id == id ? updated : u,
          ],
          page: current.page,
          limit: current.limit,
          total: current.total,
          pages: current.pages,
        ),
      );
    }
    return updated;
  }

  Future<void> deleteUser(String id) async {
    await ref.read(userRepositoryProvider).deleteUser(id);

    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      UsersPageState(
        users: current.users.where((u) => u.id != id).toList(),
        page: current.page,
        limit: current.limit,
        total: current.total - 1,
        pages: current.pages,
      ),
    );
  }
}

final userControllerProvider =
    AsyncNotifierProvider<UserController, UsersPageState>(UserController.new);
