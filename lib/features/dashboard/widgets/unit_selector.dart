import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../models/status_level.dart';

class UnitSelector extends StatelessWidget {
  final List<ColdStorageUnit> units;
  final String selectedUnitId;
  final ValueChanged<String> onUnitSelected;

  const UnitSelector({
    super.key,
    required this.units,
    required this.selectedUnitId,
    required this.onUnitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SELECT COLD STORAGE UNIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${units.length} Chambers',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 66,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: units.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final unit = units[index];
              final bool isSelected = unit.id == selectedUnitId;
              final StatusLevel status = unit.status;
              final bool isOnline = unit.reading.isOnline;

              return InkWell(
                onTap: () => onUnitSelected(unit.id),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer.withValues(alpha: 0.45)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (status == StatusLevel.good && isOnline
                              ? AppColors.border
                              : status.borderColor),
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status color pill indicator
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color:
                              isOnline ? status.color : AppColors.statusOffline,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isOnline
                                      ? status.color
                                      : AppColors.statusOffline)
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            unit.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            unit.village,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Status Label Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? status.backgroundColor
                              : AppColors.statusOfflineBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOnline
                                ? status.borderColor
                                : AppColors.statusOfflineBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isOnline ? status.systemSafeLabel : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isOnline
                                ? status.color
                                : AppColors.statusOffline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
