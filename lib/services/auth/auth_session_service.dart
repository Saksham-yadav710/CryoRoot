import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_user.dart';

/// Service responsible for persisting and restoring authentication sessions.
/// Farmers stay logged in on their device until they explicitly log out.
class AuthSessionService {
  static const String _keyUserId = 'cryoroot_logged_in_user_id';
  static const String _keyUserRole = 'cryoroot_logged_in_role';
  static const String _keyRememberMe = 'cryoroot_logged_in_remember_me';
  static const String _keyLastLoginEpoch = 'cryoroot_last_login_epoch';
  static const String _keyRegisteredFarmers = 'cryoroot_registered_farmers_v1';

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

    // Match against known pre-configured personas
    for (final user in AppUser.allUsers) {
      if (user.id == userId) {
        return user;
      }
    }

    // Check dynamically registered farmers registry
    final registered = await getRegisteredFarmersRaw();
    for (final f in registered) {
      if (f['id'] == userId) {
        final List<dynamic> unitsRaw =
            f['ownedUnitIds'] as List<dynamic>? ?? ['AC-NER-001'];
        return AppUser(
          id: f['id'] as String,
          name: f['name'] as String? ?? 'Farmer ($userId)',
          phone: f['phone'] as String? ?? '',
          role: UserRole.farmer,
          ownedUnitIds: unitsRaw.map((e) => e.toString()).toList(),
        );
      }
    }

    // If custom user was saved, reconstruct from role
    final roleString = prefs.getString(_keyUserRole) ?? 'farmer';
    final role =
        roleString == 'technician' ? UserRole.technician : UserRole.farmer;

    return AppUser(
      id: userId,
      name:
          role == UserRole.farmer ? 'Farmer ($userId)' : 'Technician ($userId)',
      phone: '',
      role: role,
      ownedUnitIds: role == UserRole.farmer ? ['AC-NER-001', 'AC-NER-002'] : [],
    );
  }

  /// Retrieves all dynamically registered farmer accounts stored on this device.
  Future<List<Map<String, dynamic>>> getRegisteredFarmersRaw() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_keyRegisteredFarmers);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Saves or updates a registered farmer in local storage.
  Future<void> saveRegisteredFarmer({
    required AppUser user,
    required String pin,
    String? village,
  }) async {
    final prefs = await _prefs;
    final list = await getRegisteredFarmersRaw();
    final cleanPhone =
        user.phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    final index = list.indexWhere((item) {
      final p =
          (item['phone'] as String? ?? '').replaceAll(RegExp(r'[\s\-\+]'), '');
      return p == cleanPhone || item['id'] == user.id;
    });

    final record = {
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
      'pin': pin.trim(),
      'role': 'farmer',
      'ownedUnitIds': user.ownedUnitIds,
      'village': village ?? 'Northeast India Cluster',
      'registeredAt': DateTime.now().toIso8601String(),
    };

    if (index != -1) {
      list[index] = record;
    } else {
      list.add(record);
    }

    await prefs.setString(_keyRegisteredFarmers, jsonEncode(list));
  }

  /// Verifies credentials for a registered farmer. Returns AppUser if valid, null otherwise.
  Future<AppUser?> authenticateRegisteredFarmer(
      String identifier, String pin) async {
    final cleanInput = identifier
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-\+]'), '');
    final cleanPin = pin.trim();
    if (cleanInput.isEmpty || cleanPin.isEmpty) return null;

    final farmers = await getRegisteredFarmersRaw();
    for (final f in farmers) {
      final phone =
          (f['phone'] as String? ?? '').replaceAll(RegExp(r'[\s\-\+]'), '');
      final id = (f['id'] as String? ?? '')
          .toLowerCase()
          .replaceAll(RegExp(r'[\s\-\+]'), '');
      final savedPin = (f['pin'] as String? ?? '').trim();

      if ((phone == cleanInput || id == cleanInput) && savedPin == cleanPin) {
        final List<dynamic> unitsRaw =
            f['ownedUnitIds'] as List<dynamic>? ?? ['AC-NER-001'];
        return AppUser(
          id: f['id'] as String? ?? 'farmer-$cleanInput',
          name: f['name'] as String? ?? 'Farmer ($identifier)',
          phone: f['phone'] as String? ?? identifier,
          role: UserRole.farmer,
          ownedUnitIds: unitsRaw.map((e) => e.toString()).toList(),
        );
      }
    }
    return null;
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
