import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import 'auth_providers.dart';

class TechnicianAuthState {
  final bool isAuthenticated;
  final AppUser? user;
  final String? errorMessage;
  final DateTime? lastLoginTime;

  const TechnicianAuthState({
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.lastLoginTime,
  });

  TechnicianAuthState copyWith({
    bool? isAuthenticated,
    AppUser? user,
    String? errorMessage,
    DateTime? lastLoginTime,
    bool clearError = false,
  }) {
    return TechnicianAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
    );
  }
}

class TechnicianAuthNotifier extends StateNotifier<TechnicianAuthState> {
  final Ref _ref;

  TechnicianAuthNotifier(this._ref) : super(const TechnicianAuthState());

  // Authorized technician credentials
  static const Map<String, String> _authorizedCredentials = {
    'tech-01': 'tech123',
    'technician': 'tech123',
    'admin@cryoroot.com': 'cryo2026',
    'tech.bikash': 'bikash2026',
  };

  /// Authenticates the technician with [userId] and [password].
  /// Returns `true` if authentication succeeds, or `false` on failure.
  bool login(String userId, String password) {
    final cleanId = userId.trim().toLowerCase();
    final cleanPass = password.trim();

    final expectedPass = _authorizedCredentials[cleanId];
    if (expectedPass != null && expectedPass == cleanPass) {
      const techUser = AppUser.technician;
      state = TechnicianAuthState(
        isAuthenticated: true,
        user: techUser,
        errorMessage: null,
        lastLoginTime: DateTime.now(),
      );

      // Sync active app persona to technician asynchronously
      Future.microtask(() {
        _ref.read(currentUserProvider.notifier).setUser(techUser);
      });
      return true;
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        errorMessage: 'Invalid Technician ID or Password. Access Denied.',
      );
      return false;
    }
  }

  /// Clears active technician session and locks the panel.
  void logout() {
    state = const TechnicianAuthState(
      isAuthenticated: false,
      user: null,
      errorMessage: null,
    );
    // Revert persona to Farmer A
    Future.microtask(() {
      _ref.read(currentUserProvider.notifier).switchToFarmerA();
    });
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final technicianAuthProvider =
    StateNotifierProvider<TechnicianAuthNotifier, TechnicianAuthState>((ref) {
  return TechnicianAuthNotifier(ref);
});
