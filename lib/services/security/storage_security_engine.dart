import '../../models/app_user.dart';
import '../../models/cold_storage_unit.dart';

class StorageSecurityEngine {
  /// Returns whether the [user] is the registered owner of this [unit].
  static bool isOwner(ColdStorageUnit unit, AppUser user) {
    if (!user.isFarmer) return false;
    return unit.ownerFarmerId == user.id;
  }

  /// Evaluates whether the [user] has authorization to modify temperature,
  /// humidity, produce presets, and operational setpoints of the [unit].
  ///
  /// Rules:
  /// 1. Farmer A can ONLY control cold storages where ownerFarmerId == farmerA.id.
  /// 2. Farmers other than Farmer A (e.g. Farmer B) CANNOT control Farmer A's unit.
  /// 3. Technicians can control the unit ONLY IF the owner has explicitly granted
  ///    [isTechnicianAccessGranted].
  static bool canControlSetpoints(ColdStorageUnit unit, AppUser user) {
    if (user.isFarmer) {
      return isOwner(unit, user);
    }

    if (user.isTechnician) {
      return unit.isTechnicianAccessGranted;
    }

    return false;
  }

  /// Strictly checks if the [user] has authority to grant or revoke
  /// technician service access for this [unit].
  ///
  /// Only the registered owner farmer can grant/revoke technician access.
  static bool canToggleTechnicianAccess(ColdStorageUnit unit, AppUser user) {
    return isOwner(unit, user);
  }

  /// Generates human-readable security status description for the UI.
  static String getAccessStatusMessage(ColdStorageUnit unit, AppUser user) {
    if (user.isFarmer) {
      if (isOwner(unit, user)) {
        return 'You are the registered owner (${unit.ownerFarmerName}). Full climate control is active.';
      } else {
        return 'Access Restricted: This cold storage is owned by ${unit.ownerFarmerName}. As ${user.name}, you have view-only access.';
      }
    }

    if (user.isTechnician) {
      if (unit.isTechnicianAccessGranted) {
        return 'Authorized Technician Mode: ${unit.ownerFarmerName} has granted active servicing permission.';
      } else {
        return 'Technician Control Locked: Owner (${unit.ownerFarmerName}) has not granted service authorization.';
      }
    }

    return 'View-only access.';
  }
}
