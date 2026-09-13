import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../state/auth_providers.dart';

class UserRoleSwitcherBar extends ConsumerWidget {
  const UserRoleSwitcherBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: currentUser.isFarmer
                          ? AppColors.primaryLight
                          : AppColors.primaryDark.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentUser.isFarmer
                          ? Icons.person_rounded
                          : Icons.engineering_rounded,
                      size: 16,
                      color: currentUser.isFarmer
                          ? AppColors.primary
                          : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE DEMO PERSONA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        currentUser.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: currentUser.isFarmer
                      ? AppColors.primaryContainer
                      : AppColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentUser.role.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: currentUser.isFarmer
                        ? AppColors.primaryDark
                        : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPersonaChip(
                  label: '👨‍🌾 Farmer A (Ramesh)',
                  subtitle: 'Owner of Unit 1 & 2',
                  isSelected: currentUser.id == AppUser.farmerA.id,
                  onTap: () =>
                      ref.read(currentUserProvider.notifier).switchToFarmerA(),
                ),
                const SizedBox(width: 6),
                _buildPersonaChip(
                  label: '👨‍🌾 Farmer B (Suresh)',
                  subtitle: 'Owner of Unit 3',
                  isSelected: currentUser.id == AppUser.farmerB.id,
                  onTap: () =>
                      ref.read(currentUserProvider.notifier).switchToFarmerB(),
                ),
                const SizedBox(width: 6),
                _buildPersonaChip(
                  label: '🔧 Field Tech (Bikash)',
                  subtitle: 'Service Engineer',
                  isSelected: currentUser.id == AppUser.technician.id,
                  onTap: () =>
                      ref.read(currentUserProvider.notifier).switchToTechnician(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaChip({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8.5,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
