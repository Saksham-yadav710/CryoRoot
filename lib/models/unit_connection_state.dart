import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum UnitConnectionState {
  live,
  stale,
  offline,
  syncing;

  String get label {
    switch (this) {
      case UnitConnectionState.live:
        return 'LIVE';
      case UnitConnectionState.stale:
        return 'CONNECTION SLOW';
      case UnitConnectionState.offline:
        return 'OFFLINE';
      case UnitConnectionState.syncing:
        return 'SYNCING';
    }
  }

  Color get color {
    switch (this) {
      case UnitConnectionState.live:
        return AppColors.statusGood;
      case UnitConnectionState.stale:
        return AppColors.statusAttention;
      case UnitConnectionState.offline:
        return AppColors.statusOffline;
      case UnitConnectionState.syncing:
        return AppColors.primary;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case UnitConnectionState.live:
        return AppColors.statusGoodBg;
      case UnitConnectionState.stale:
        return AppColors.statusAttentionBg;
      case UnitConnectionState.offline:
        return AppColors.statusOfflineBg;
      case UnitConnectionState.syncing:
        return AppColors.primaryLight;
    }
  }

  Color get borderColor {
    switch (this) {
      case UnitConnectionState.live:
        return AppColors.statusGoodBorder;
      case UnitConnectionState.stale:
        return AppColors.statusAttentionBorder;
      case UnitConnectionState.offline:
        return AppColors.statusOfflineBorder;
      case UnitConnectionState.syncing:
        return AppColors.primary;
    }
  }

  IconData get icon {
    switch (this) {
      case UnitConnectionState.live:
        return Icons.sensors_rounded;
      case UnitConnectionState.stale:
        return Icons.hourglass_top_rounded;
      case UnitConnectionState.offline:
        return Icons.sensors_off_rounded;
      case UnitConnectionState.syncing:
        return Icons.sync_rounded;
    }
  }

  /// Converts a timestamp into farmer-friendly human language (e.g. "just now", "12s ago", "3m ago")
  static String formatRelativeTime(DateTime? timestamp) {
    if (timestamp == null) return 'No data';
    final difference = DateTime.now().difference(timestamp);

    if (difference.isNegative || difference.inSeconds < 10) {
      return 'just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
