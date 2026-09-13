import 'dart:convert';
import '../../models/crop_profile.dart';

/// Repository for storing and retrieving user-added custom crops.
class UserCropRepository {
  final List<CropProfile> _customCrops = [];

  List<CropProfile> getCustomCrops() {
    return List.unmodifiable(_customCrops);
  }

  void addCrop(CropProfile crop) {
    // Avoid duplicate IDs
    _customCrops.removeWhere((c) =>
        c.id == crop.id || c.name.toLowerCase() == crop.name.toLowerCase());
    _customCrops.insert(0, crop);
  }

  void removeCrop(String id) {
    _customCrops.removeWhere((c) => c.id == id);
  }

  String serialize() {
    final list = _customCrops.map((c) => c.toJson()).toList();
    return jsonEncode(list);
  }

  void deserialize(String jsonStr) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _customCrops.clear();
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          _customCrops.add(CropProfile.fromJson(item));
        }
      }
    } catch (_) {
      // Graceful fallback if empty or malformed
    }
  }
}
