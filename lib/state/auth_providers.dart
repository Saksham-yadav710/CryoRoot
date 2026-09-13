import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

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
