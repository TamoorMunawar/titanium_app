import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/network/jwt_utils.dart';
import '../core/storage/token_storage.dart';
import '../models/auth/auth_user.dart';
import '../repositories/auth_repository.dart';

final Provider<TokenStorage> tokenStorageProvider =
    Provider<TokenStorage>((ref) => TokenStorage());

// Explicitly typed (rather than `final dioProvider = ...`) to break a
// top-level type-inference cycle: this closure references
// authControllerProvider (deferred, inside a nested callback — only
// resolved once a request actually 401s, not at provider-construction
// time), and authControllerProvider itself depends on dioProvider via
// authRepositoryProvider.
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return buildDioClient(
    tokenStorage,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).logout(),
  );
});

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._tokenStorage) : super(const AuthState());

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  Future<bool> login({
    required String email,
    required String password,
    required String usertype,
    double? lat,
    double? lng,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.login(
        email: email,
        password: password,
        usertype: usertype,
        lat: lat,
        lng: lng,
        address: address,
      );
      await _tokenStorage.saveSession(result.token, result.user.toJson());
      state = AuthState(user: result.user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.guestLogin();
      await _tokenStorage.saveSession(result.token, result.user.toJson());
      state = AuthState(user: result.user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Restores a previously logged-in session on app launch, as long as the
  /// stored token hasn't passed its 24h expiry. Returns the restored user,
  /// or null if there was nothing valid to restore.
  Future<AuthUser?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;

    final expiry = decodeJwtExpiry(token);
    if (expiry == null || expiry.isBefore(DateTime.now())) {
      await _tokenStorage.clearSession();
      return null;
    }

    final userJson = await _tokenStorage.readUser();
    if (userJson == null) {
      await _tokenStorage.clearSession();
      return null;
    }

    final user = AuthUser.fromJson(userJson);
    state = AuthState(user: user);
    return user;
  }

  Future<void> logout() async {
    await _tokenStorage.clearSession();
    state = const AuthState();
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});
