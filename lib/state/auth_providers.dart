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
  Future<void>? _initFuture;

  AuthNotifier(this._ref, this._sessionService) : super(const AuthState()) {
    _initFuture = initSession();
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
    if (_initFuture != null) await _initFuture;
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
    // If not Farmer A or B, check dynamically registered farmers on this device
    if (matchedUser == null) {
      final registeredFarmer =
          await _sessionService.authenticateRegisteredFarmer(cleanId, cleanPin);
      if (registeredFarmer != null) {
        matchedUser = registeredFarmer;
      }
      // General 10-digit number with standard 1234 PIN (Demo fallback)
      else if (cleanId.length >= 10 &&
          (cleanPin == '1234' || cleanPin == 'farmer123')) {
        matchedUser = AppUser(
          id: 'farmer-${cleanId.substring(cleanId.length - 4)}',
          name: 'Farmer ($identifier)',
          phone: identifier,
          role: UserRole.farmer,
          ownedUnitIds: ['AC-NER-001'],
        );
      }
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
        errorMessage: 'Invalid Mobile Number or PIN. Please check your credentials or register.',
      );
      return false;
    }
  }

  /// Registers a new farmer client on this device with their custom details.
  /// Automatically persists their account and logs them in.
  Future<bool> registerFarmer({
    required String name,
    required String phone,
    required String pin,
    required List<String> ownedUnitIds,
    String? village,
  }) async {
    if (_initFuture != null) await _initFuture;
    state = state.copyWith(isLoading: true, clearError: true);

    final cleanName = name.trim();
    final cleanPhone = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    final cleanPin = pin.trim();

    if (cleanName.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter your full name.',
      );
      return false;
    }

    if (cleanPhone.length < 10) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid 10-digit mobile number.',
      );
      return false;
    }

    if (cleanPin.length != 4 || int.tryParse(cleanPin) == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please choose a 4-digit numeric PIN.',
      );
      return false;
    }

    // Check if mobile number is already registered
    final existingFarmers = await _sessionService.getRegisteredFarmersRaw();
    final isDuplicate = existingFarmers.any((f) {
      final p = (f['phone'] as String? ?? '').replaceAll(RegExp(r'[\s\-\+]'), '');
      return p == cleanPhone;
    });

    if (isDuplicate) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'This mobile number is already registered. Please log in.',
      );
      return false;
    }

    final newId = 'farmer-${cleanPhone.substring(cleanPhone.length - 4)}';
    final assignedUnits =
        ownedUnitIds.isNotEmpty ? ownedUnitIds : ['AC-NER-001'];

    final newUser = AppUser(
      id: newId,
      name: cleanName,
      phone: phone.trim(),
      role: UserRole.farmer,
      ownedUnitIds: assignedUnits,
    );

    // Save to persistent registry
    await _sessionService.saveRegisteredFarmer(
      user: newUser,
      pin: cleanPin,
      village: village,
    );

    // Save active login session
    await _sessionService.saveSession(newUser, rememberMe: true);

    state = AuthState(
      isInitialized: true,
      isAuthenticated: true,
      currentUser: newUser,
      errorMessage: null,
      isLoading: false,
    );

    _ref.read(currentUserProvider.notifier).setUser(newUser);
    return true;
  }

  /// Technician login with User ID and Password.
  Future<bool> loginTechnician({
    required String userId,
    required String password,
    bool rememberMe = true,
  }) async {
    if (_initFuture != null) await _initFuture;
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
