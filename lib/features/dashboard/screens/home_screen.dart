import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../state/storage_providers.dart';
import '../../../state/audio_providers.dart';
import '../../../state/transit_providers.dart';
import '../../produce/screens/produce_screen.dart';
import '../widgets/home_header.dart';
import '../widgets/overall_status_banner.dart';
import '../widgets/unit_selector.dart';
import '../widgets/selected_unit_hero_card.dart';
import '../widgets/telemetry_grid.dart';
import '../widgets/recommendation_card.dart';
import '../../settings/widgets/voice_settings_sheet.dart';
import '../../../state/auth_providers.dart';
import '../../../core/widgets/responsive_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(storageUnitsProvider);
    final selectedUnitId = ref.watch(selectedUnitIdProvider);
    final selectedUnit = ref.watch(selectedUnitProvider);
    final summary = ref.watch(overallSummaryProvider);
    final isAudioPlaying = ref.watch(isAudioPlayingProvider);
    final enhancedAudio = ref.watch(enhancedAudioControllerProvider);
    final alerts = ref.watch(activeAlertsProvider);

    final unreadAlertsCount = alerts.where((a) => !a.isAcknowledged).length;
    final connectionState =
        ref.watch(unitConnectionStateProvider(selectedUnit?.id ?? ''));
    final freshnessText =
        ref.watch(unitFreshnessTextProvider(selectedUnit?.id ?? ''));

    if (selectedUnit == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. Top AgriCool Branding Header with Language Pill & Simulator
          HomeHeader(
            unreadAlertsCount: unreadAlertsCount,
            onAlertsPressed: () => context.go('/alerts'),
            onProfilePressed: () => _showProfileModal(context, ref),
            onSimulatorPressed: () => context.push('/simulator'),
          ),

          // 2. Scrollable Dashboard Body
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.read(storageUnitsProvider.notifier).refreshFromMock();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Sensor data updated from cold storage telemetry.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ResponsiveCenter(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Overall System Health & Connectivity Summary Banner
                    OverallStatusBanner(
                      summary: summary,
                      units: units,
                      onUnitTapped: (unitId) {
                        ref.read(selectedUnitIdProvider.notifier).state =
                            unitId;
                      },
                    ),

                    // Multi-Storage Unit Selector
                    UnitSelector(
                      units: units,
                      selectedUnitId: selectedUnitId,
                      onUnitSelected: (unitId) {
                        ref.read(selectedUnitIdProvider.notifier).state =
                            unitId;
                        if (isAudioPlaying) {
                          enhancedAudio.stop();
                        }
                      },
                    ),

                    const SizedBox(height: 6),

                    // Selected Cold Storage Hero Card (Branding, Status, Connection, Listen, Details)
                    SelectedUnitHeroCard(
                      unit: selectedUnit,
                      connectionState: connectionState,
                      freshnessText: freshnessText,
                      isPlayingAudio: isAudioPlaying,
                      onListenPressed: () {
                        if (isAudioPlaying) {
                          enhancedAudio.stop();
                        } else {
                          enhancedAudio.speakUnitOverview(selectedUnit);
                        }
                      },
                      onViewDetailsPressed: () {
                        context.push('/storage/${selectedUnit.id}');
                      },
                    ),

                    // Key Storage Telemetry Grid (Value + Status + Explanation)
                    TelemetryGrid(reading: selectedUnit.reading),

                    // Farmer Recommendation & Action guidance
                    RecommendationCard(
                      unit: selectedUnit,
                      onActionDetailsPressed: () =>
                          _showActionGuideModal(context, selectedUnit),
                    ),

                    // Active Cold Chain Transits Banner (if any)
                    Consumer(
                      builder: (context, ref, _) {
                        final activeTransits =
                            ref.watch(activeTransitsProvider);
                        if (activeTransits.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(produceTabSelectionProvider.notifier)
                                  .state = 1;
                              context.go('/produce');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('🚚',
                                        style: TextStyle(fontSize: 22)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${activeTransits.length} Consignment${activeTransits.length > 1 ? 's' : ''} in Cold Transit',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'En route to ${activeTransits.first.destinationMandi}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  void _showProfileModal(BuildContext context, WidgetRef ref) {
    final selectedVoice = ref.watch(selectedVoiceLanguageProvider);
    final currentUser = ref.watch(currentUserProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentUser.isTechnician ? 'Technician Profile' : 'Farmer Profile & Preferences',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: currentUser.isTechnician
                      ? const Color(0xFF1E3A8A)
                      : AppColors.primary,
                  child: Icon(
                    currentUser.isTechnician
                        ? Icons.engineering_rounded
                        : Icons.agriculture_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  currentUser.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${currentUser.role.name.toUpperCase()} • ${currentUser.phone.isNotEmpty ? currentUser.phone : currentUser.id}\nChambers: ${currentUser.ownedUnitIds.isEmpty ? 'All Field Units' : currentUser.ownedUnitIds.join(', ')}',
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: const Text('Voice Guide Language'),
                subtitle: Text(
                    '${selectedVoice.flagEmoji} ${selectedVoice.label} (${selectedVoice.nativeName})'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
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
              ),
              ListTile(
                leading:
                    const Icon(Icons.tune_rounded, color: AppColors.primary),
                title: const Text('Hardware Sensor Simulator'),
                subtitle:
                    const Text('Debug telemetry sliders & one-tap presets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/simulator');
                },
              ),
              const ListTile(
                leading: Icon(Icons.support_agent, color: AppColors.primary),
                title: Text('Krishi Vigyan Kendra Helpline'),
                subtitle: Text('Toll-free 1800-180-1551'),
                trailing: Icon(Icons.call),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                subtitle: const Text(
                  'Sign out of this device and return to login portal',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmationDialog(context, ref);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
              SizedBox(width: 8),
              Text('Log Out of CryoRoots?'),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out? Your saved session on this device will be cleared, and you will need to log in again with your PIN or password.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              child: const Text('LOG OUT'),
            ),
          ],
        );
      },
    );
  }

  void _showActionGuideModal(BuildContext context, ColdStorageUnit unit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    unit.status.icon,
                    color: unit.status.color,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'What Should I Do?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Current Status: ${unit.status.systemSafeLabel}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: unit.status.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unit.recommendedAction,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Action Steps for Farmer:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (unit.reading.doorOpen) ...[
                const Text('1. Visit the storage unit physically.'),
                const Text('2. Ensure door seals are tightly shut.'),
                const Text(
                    '3. Check that produce crates are not blocking the entrance.'),
              ] else if (!unit.reading.gridPower) ...[
                const Text(
                    '1. Grid is currently down; PCM thermal battery is active.'),
                const Text(
                    '2. Avoid opening the door frequently to preserve cold temperature.'),
                const Text(
                    '3. Solar panels are keeping the ventilation and control system powered.'),
              ] else ...[
                const Text(
                    '• Storage operating at recommended standards. No intervention required.'),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('UNDERSTOOD'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
