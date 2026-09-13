import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/audio_providers.dart';
import '../../settings/widgets/voice_settings_sheet.dart';
import 'direct_connect_modal.dart';

class HomeHeader extends ConsumerWidget {
  final int unreadAlertsCount;
  final VoidCallback onAlertsPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback? onSimulatorPressed;

  const HomeHeader({
    super.key,
    required this.unreadAlertsCount,
    required this.onAlertsPressed,
    required this.onProfilePressed,
    this.onSimulatorPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(selectedVoiceLanguageProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // App Branding Icon & Logo
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.solar_power_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'CryoRoot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Smart Solar Cold Storage',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Quick Voice Language Selector Pill with Accessibility Support
            Semantics(
              button: true,
              label:
                  'Select voice language, current language is ${selectedLanguage.displayName}',
              child: Tooltip(
                message:
                    'Change voice language (${selectedLanguage.displayName})',
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (ctx) => const VoiceSettingsSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedLanguage.flagEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedLanguage.code.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Offline Direct Sensor Sync Button (Bluetooth / Wi-Fi AP)
            IconButton(
              icon: const Icon(
                Icons.bluetooth_searching_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              onPressed: () => DirectConnectModal.show(context),
              tooltip: 'Direct Offline Chamber Sync (BLE / Wi-Fi)',
            ),
            // Hardware Simulator Button
            if (onSimulatorPressed != null)
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
                onPressed: onSimulatorPressed,
                tooltip: 'Hardware Sensor Simulator',
              ),
            // Alerts Button with badge
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  if (unreadAlertsCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.statusCritical,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadAlertsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: onAlertsPressed,
              tooltip: 'Alerts',
            ),
            // Profile & Settings
            IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: AppColors.textPrimary,
                size: 24,
              ),
              onPressed: onProfilePressed,
              tooltip: 'Profile & Settings',
            ),
          ],
        ),
      ),
    );
  }
}
