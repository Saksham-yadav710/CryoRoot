import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_user.dart';

/// Service responsible for persisting and restoring authentication sessions.
/// Farmers stay logged in on their device until they explicitly log out.
class AuthSessionService {
  static const String _keyUserId = 'cryoroot_logged_in_user_id';
  static const String _keyUserRole = 'cryoroot_logged_in_role';
  static const String _keyRememberMe = 'cryoroot_logged_in_remember_me';
  static const String _keyLastLoginEpoch = 'cryoroot_last_login_epoch';

  final SharedPreferences? _injectedPrefs;

  const AuthSessionService([this._injectedPrefs]);

  Future<SharedPreferences> get _prefs async =>
      _injectedPrefs ?? await SharedPreferences.getInstance();

  /// Retrieves the saved user session if one exists.
  /// Returns null if no user is logged in.
  Future<AppUser?> getSavedSession() async {
    final prefs = await _prefs;
    final userId = prefs.getString(_keyUserId);
    if (userId == null || userId.isEmpty) {
      return null;
    }

    // Match against known pre-configured personas or find matching ID
    for (final user in AppUser.allUsers) {
      if (user.id == userId) {
        return user;
      }
    }

    // If custom user was saved, reconstruct from role
    final roleString = prefs.getString(_keyUserRole) ?? 'farmer';
    final role = roleString == 'technician' ? UserRole.technician : UserRole.farmer;

    return AppUser(
      id: userId,
      name: role == UserRole.farmer ? 'Farmer ($userId)' : 'Technician ($userId)',
      phone: '',
      role: role,
      ownedUnitIds: role == UserRole.farmer ? ['AC-NER-001', 'AC-NER-002'] : [],
    );
  }

  /// Saves the user session to persistent storage.
  /// When [rememberMe] is true (default for farmers), the session persists indefinitely.
  Future<void> saveSession(AppUser user, {bool rememberMe = true}) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserRole, user.isTechnician ? 'technician' : 'farmer');
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setInt(_keyLastLoginEpoch, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clears the saved session from persistent storage on explicit logout.
  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyLastLoginEpoch);
  }

  /// Checks if there is an active persisted session.
  Future<bool> hasActiveSession() async {
    final prefs = await _prefs;
    return prefs.containsKey(_keyUserId) && (prefs.getString(_keyUserId)?.isNotEmpty ?? false);
  }
}
