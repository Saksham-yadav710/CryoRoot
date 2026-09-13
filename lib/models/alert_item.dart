import 'status_level.dart';

class AlertItem {
  final String id;
  final String unitId;
  final String unitName;
  final String title;
  final StatusLevel severity;
  final String currentValue;
  final String expectedValue;
  final String duration;
  final String possibleCause;
  final String recommendedAction;
  final DateTime timestamp;
  final bool isAcknowledged;

  const AlertItem({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.title,
    required this.severity,
    required this.currentValue,
    required this.expectedValue,
    required this.duration,
    required this.possibleCause,
    required this.recommendedAction,
    required this.timestamp,
    this.isAcknowledged = false,
  });

  AlertItem copyWith({
    String? id,
    String? unitId,
    String? unitName,
    String? title,
    StatusLevel? severity,
    String? currentValue,
    String? expectedValue,
    String? duration,
    String? possibleCause,
    String? recommendedAction,
    DateTime? timestamp,
    bool? isAcknowledged,
  }) {
    return AlertItem(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      title: title ?? this.title,
      severity: severity ?? this.severity,
      currentValue: currentValue ?? this.currentValue,
      expectedValue: expectedValue ?? this.expectedValue,
      duration: duration ?? this.duration,
      possibleCause: possibleCause ?? this.possibleCause,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }
}
