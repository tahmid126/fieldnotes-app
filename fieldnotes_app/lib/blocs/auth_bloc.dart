import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

// EVENTS
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  AuthLoginSubmitted(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;
  AuthRegisterSubmitted(this.name, this.email, this.password);

  @override
  List<Object?> get props => [name, email, password];
}

class AuthLogoutRequested extends AuthEvent {}

// STATES
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// BLOC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _api = ApiService.instance;
  final SyncService _sync = SyncService.instance;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.authTokenKey);
    final email = prefs.getString(AppConstants.userEmailKey);
    final name = prefs.getString(AppConstants.userNameKey);
    final id = prefs.getString(AppConstants.userIdKey);

    if (token != null && email != null) {
      emit(AuthAuthenticated(UserModel(
        id: id ?? '',
        name: name ?? '',
        email: email,
        token: token,
      )));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _api.login(event.email, event.password);
      final prefs = await SharedPreferences.getInstance();
      final prevUserId = prefs.getString(AppConstants.userIdKey);

      // If switching accounts or first login, clear previous user's local database!
      if (prevUserId != user.id) {
        await DatabaseService.instance.clearAll();
        await prefs.remove(AppConstants.lastSyncKey);
      }

      await prefs.setString(AppConstants.authTokenKey, user.token ?? '');
      await prefs.setString(AppConstants.userEmailKey, user.email);
      await prefs.setString(AppConstants.userNameKey, user.name);
      await prefs.setString(AppConstants.userIdKey, user.id);

      // Trigger sync for this user
      _sync.performSync();

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegisterSubmitted(AuthRegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _api.register(event.name, event.email, event.password);
      final prefs = await SharedPreferences.getInstance();

      // Brand new registration: wipe local DB and sync cursor so no previous user data bleeds!
      await DatabaseService.instance.clearAll();
      await prefs.remove(AppConstants.lastSyncKey);

      await prefs.setString(AppConstants.authTokenKey, user.token ?? '');
      await prefs.setString(AppConstants.userEmailKey, user.email);
      await prefs.setString(AppConstants.userNameKey, user.name);
      await prefs.setString(AppConstants.userIdKey, user.id);

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.lastSyncKey);

    // Clear local SQLite database on logout to guarantee absolute data privacy between accounts
    await DatabaseService.instance.clearAll();

    emit(AuthUnauthenticated());
  }
}
