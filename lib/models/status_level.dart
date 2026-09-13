import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum StatusLevel {
  good,
  attention,
  warning,
  critical,
  offline;

  String get label {
    switch (this) {
      case StatusLevel.good:
        return 'GOOD';
      case StatusLevel.attention:
        return 'ATTENTION';
      case StatusLevel.warning:
        return 'WARNING';
      case StatusLevel.critical:
        return 'CRITICAL';
      case StatusLevel.offline:
        return 'OFFLINE';
    }
  }

  String get systemSafeLabel {
    switch (this) {
      case StatusLevel.good:
        return 'SAFE';
      case StatusLevel.attention:
        return 'ATTENTION';
      case StatusLevel.warning:
        return 'WARNING';
      case StatusLevel.critical:
        return 'CRITICAL';
      case StatusLevel.offline:
        return 'OFFLINE';
    }
  }

  Color get color {
    switch (this) {
      case StatusLevel.good:
        return AppColors.statusGood;
      case StatusLevel.attention:
        return AppColors.statusAttention;
      case StatusLevel.warning:
        return AppColors.statusWarning;
      case StatusLevel.critical:
        return AppColors.statusCritical;
      case StatusLevel.offline:
        return AppColors.statusOffline;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StatusLevel.good:
        return AppColors.statusGoodBg;
      case StatusLevel.attention:
        return AppColors.statusAttentionBg;
      case StatusLevel.warning:
        return AppColors.statusWarningBg;
      case StatusLevel.critical:
        return AppColors.statusCriticalBg;
      case StatusLevel.offline:
        return AppColors.statusOfflineBg;
    }
  }

  Color get borderColor {
    switch (this) {
      case StatusLevel.good:
        return AppColors.statusGoodBorder;
      case StatusLevel.attention:
        return AppColors.statusAttentionBorder;
      case StatusLevel.warning:
        return AppColors.statusWarningBorder;
      case StatusLevel.critical:
        return AppColors.statusCriticalBorder;
      case StatusLevel.offline:
        return AppColors.statusOfflineBorder;
    }
  }

  IconData get icon {
    switch (this) {
      case StatusLevel.good:
        return Icons.check_circle_rounded;
      case StatusLevel.attention:
        return Icons.info_rounded;
      case StatusLevel.warning:
        return Icons.warning_amber_rounded;
      case StatusLevel.critical:
        return Icons.error_rounded;
      case StatusLevel.offline:
        return Icons.cloud_off_rounded;
    }
  }
}
