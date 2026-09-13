import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth/auth_session_service.dart';
import 'technician_auth_provider.dart';

/// Provider for persistent session storage service.
final authSessionServiceProvider = Provider<AuthSessionService>((ref) {
  return const AuthSessionService();
});

/// Current active user persona (Farmer A, Farmer B, or Technician).
/// Maintained for direct widget access and security engine compatibility.
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AppUser>((ref) {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends StateNotifier<AppUser> {
  CurrentUserNotifier() : super(AppUser.farmerA);

  void setUser(AppUser user) {
    state = user;
  }

  void switchToFarmerA() {
    state = AppUser.farmerA;
  }

  void switchToFarmerB() {
    state = AppUser.farmerB;
  }

  void switchToTechnician() {
    state = AppUser.technician;
  }
}

/// Authentication state model
class AuthState {
  final bool isInitialized;
  final bool isAuthenticated;
  final AppUser? currentUser;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.isInitialized = false,
    this.isAuthenticated = false,
    this.currentUser,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isFarmer => currentUser?.isFarmer ?? false;
  bool get isTechnician => currentUser?.isTechnician ?? false;

  AuthState copyWith({
    bool? isInitialized,
    bool? isAuthenticated,
    AppUser? currentUser,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthSessionService _sessionService;

  AuthNotifier(this._ref, this._sessionService) : super(const AuthState()) {
    initSession();
  }

  /// Restores session on app startup.
  /// If a saved farmer session exists, logs them in automatically without asking again.
  Future<void> initSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final savedUser = await _sessionService.getSavedSession();
      if (savedUser != null) {
        state = AuthState(
          isInitialized: true,
          isAuthenticated: true,
          currentUser: savedUser,
          errorMessage: null,
          isLoading: false,
        );
        _ref.read(currentUserProvider.notifier).setUser(savedUser);
        if (savedUser.isTechnician) {
          _ref.read(technicianAuthProvider.notifier).login('tech-01', 'tech123');
        }
      } else {
        state = const AuthState(
          isInitialized: true,
          isAuthenticated: false,
          currentUser: null,
          errorMessage: null,
          isLoading: false,
        );
      }
    } catch (e) {
      state = const AuthState(
        isInitialized: true,
        isAuthenticated: false,
        currentUser: null,
        errorMessage: null,
        isLoading: false,
      );
    }
  }

  /// Farmer login with Phone Number / Farmer ID and 4-digit PIN.
  /// When successful, session is persisted so the farmer stays logged in until explicit logout.
  Future<bool> loginFarmer({
    required String identifier,
    required String pinOrPassword,
    bool rememberMe = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final cleanId = identifier.trim().toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    final cleanPin = pinOrPassword.trim();

    AppUser? matchedUser;

    // Check Farmer A
    if (cleanId == 'farmer-a' ||
        cleanId == 'farmera' ||
        cleanId == '9876511001' ||
        cleanId == '+919876511001') {
      if (cleanPin == '1234' || cleanPin == 'farmer123' || cleanPin == 'farmer') {
        matchedUser = AppUser.farmerA;
      }
    }
    // Check Farmer B
    else if (cleanId == 'farmer-b' ||
        cleanId == 'farmerb' ||
        cleanId == '9876522002' ||
        cleanId == '+919876522002') {
      if (cleanPin == '1234' || cleanPin == 'farmer123' || cleanPin == 'farmer') {
        matchedUser = AppUser.farmerB;
      }
    }
    // General 10-digit number with standard 1234 PIN
    else if (cleanId.length >= 10 && (cleanPin == '1234' || cleanPin == 'farmer123')) {
      matchedUser = AppUser(
        id: 'farmer-${cleanId.substring(cleanId.length - 4)}',
        name: 'Farmer ($identifier)',
        phone: identifier,
        role: UserRole.farmer,
        ownedUnitIds: ['AC-NER-001'],
      );
    }

    if (matchedUser != null) {
      if (rememberMe) {
        await _sessionService.saveSession(matchedUser, rememberMe: true);
      }
      state = AuthState(
        isInitialized: true,
        isAuthenticated: true,
        currentUser: matchedUser,
        errorMessage: null,
        isLoading: false,
      );
      _ref.read(currentUserProvider.notifier).setUser(matchedUser);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid Phone Number or PIN. Use Demo: 98765 11001 / PIN: 1234',
      );
      return false;
    }
  }

  /// Technician login with User ID and Password.
  Future<bool> loginTechnician({
    required String userId,
    required String password,
    bool rememberMe = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final isTechAuth = _ref.read(technicianAuthProvider.notifier).login(userId, password);
    if (isTechAuth) {
      const techUser = AppUser.technician;
      if (rememberMe) {
        await _sessionService.saveSession(techUser, rememberMe: rememberMe);
      }
      state = const AuthState(
        isInitialized: true,
        isAuthenticated: true,
        currentUser: techUser,
        errorMessage: null,
        isLoading: false,
      );
      _ref.read(currentUserProvider.notifier).setUser(techUser);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid Technician ID or Service Password. Access Denied.',
      );
      return false;
    }
  }

  /// Logs out the user, purges persistent session, and returns to Login Portal.
  Future<void> logout() async {
    await _sessionService.clearSession();
    _ref.read(technicianAuthProvider.notifier).logout();
    state = const AuthState(
      isInitialized: true,
      isAuthenticated: false,
      currentUser: null,
      errorMessage: null,
      isLoading: false,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final sessionService = ref.watch(authSessionServiceProvider);
  return AuthNotifier(ref, sessionService);
});
