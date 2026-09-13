import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/responsive_layout.dart';
import '../dashboard/widgets/live_audio_player_bar.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        bottomSheet: const LiveAudioPlayerBar(),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primaryLight,
              minWidth: 72,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.solar_power_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'CryoRoot',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon:
                      Icon(Icons.home_rounded, color: AppColors.primary),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon:
                      Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                  label: Text('Produce'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon:
                      Icon(Icons.storefront_rounded, color: AppColors.primary),
                  label: Text('Market'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.notifications_none_rounded),
                  selectedIcon:
                      Icon(Icons.notifications_rounded, color: AppColors.primary),
                  label: Text('Alerts'),
                ),
              ],
            ),
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: AppColors.border,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomSheet: const LiveAudioPlayerBar(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon:
                  Icon(Icons.inventory_2_rounded, color: AppColors.primary),
              label: 'Produce',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon:
                  Icon(Icons.storefront_rounded, color: AppColors.primary),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded),
              selectedIcon:
                  Icon(Icons.notifications_rounded, color: AppColors.primary),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
