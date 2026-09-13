import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/alert_item.dart';
import '../../../models/status_level.dart';

class ActionGuideDialog extends StatefulWidget {
  final AlertItem alert;
  final VoidCallback onAcknowledge;

  const ActionGuideDialog({
    super.key,
    required this.alert,
    required this.onAcknowledge,
  });

  @override
  State<ActionGuideDialog> createState() => _ActionGuideDialogState();
}

class _ActionGuideDialogState extends State<ActionGuideDialog> {
  final Map<int, bool> _checkedSteps = {};

  List<String> get _actionSteps {
    final alert = widget.alert;
    if (alert.title.contains('Door')) {
      return [
        'Visit the cold storage unit physically.',
        'Inspect the main door rubber seal for debris or crate obstruction.',
        'Push the door handle until the mechanical latch firmly locks.',
        'Check that the internal cooling fan begins normal circulation.',
      ];
    } else if (alert.title.contains('Grid') || alert.title.contains('Power')) {
      return [
        'PCM thermal backup is currently active and protecting your produce.',
        'Keep chamber doors strictly closed to minimize cold loss.',
        'Check if main circuit breaker (MCB) on the solar inverter is in UP position.',
        'Monitor remaining PCM hours in the CryoRoots app.',
      ];
    } else if (alert.title.contains('Battery')) {
      return [
        'Check solar panels on roof for excessive dust, bird droppings, or fallen leaves.',
        'Turn off optional interior chamber work lights.',
        'Ensure inverter DC disconnect switch is turned ON.',
      ];
    } else if (alert.title.contains('Water')) {
      return [
        'Locate the ultrasonic humidifier reservoir beneath the evaporator.',
        'Refill with 10-15 liters of clean filtered or RO water.',
        'Ensure the humidifier float switch moves freely.',
      ];
    } else {
      return [
        'Inspect chamber internal temperature reading on external display.',
        'Ensure ventilation grilles around compressor outdoor unit are unblocked.',
        'Verify power indicator on ESP32 IoT gateway.',
        'Contact CryoRoots Support if temperature does not normalize within 30 minutes.',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final StatusLevel severity = alert.severity;
    final steps = _actionSteps;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title & Close Button
            Row(
              children: [
                Icon(severity.icon, color: severity.color, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WHAT SHOULD I DO?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: severity.color,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Diagnostic Box (Current vs Target + Possible Cause)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: severity.backgroundColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: severity.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Unit: ${alert.unitName}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      Text('Duration: ${alert.duration}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: severity.color)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current: ${alert.currentValue}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                      Text('Target: ${alert.expectedValue}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Root Cause: ${alert.possibleCause}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Step-by-Step Resolution Checklist
            const Text(
              'STEP-BY-STEP RESOLUTION CHECKLIST',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            ...List.generate(steps.length, (index) {
              final isChecked = _checkedSteps[index] ?? false;
              return InkWell(
                onTap: () {
                  setState(() {
                    _checkedSteps[index] = !isChecked;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppColors.primaryLight.withValues(alpha: 0.5)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChecked
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: isChecked
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          steps[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isChecked ? FontWeight.w700 : FontWeight.w500,
                            color: isChecked
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                            decoration:
                                isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // Helpline Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need technician support? Toll-Free 1800-180-1551',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAcknowledge();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: severity.color,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ACKNOWLEDGE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
