// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/shared/models/session_models.dart';

/// セッション管理ユーティリティ
class SessionUtils {
  /// 再認証までの残り時間を計算（RefreshJWT期限ベース）
  static Duration? getTimeRemaining(DateTime? tokenExpiry) {
    if (tokenExpiry == null) {
      debugPrint('⚠️ [SESSION] RefreshJWT expiry is null');
      return null;
    }
    final now = DateTime.now();
    if (tokenExpiry.isBefore(now)) {
      debugPrint('⚠️ [SESSION] RefreshJWT expired at $tokenExpiry - re-auth required');
      return Duration.zero;
    }
    final remaining = tokenExpiry.difference(now);
    debugPrint('✅ [SESSION] Time until re-auth needed: ${remaining.inDays} days, ${remaining.inHours % 24} hours');
    return remaining;
  }

  /// 表示用の時間文字列を生成
  static String formatTimeRemaining(
    Duration? duration,
    AppLocalizations l10n,
  ) {
    if (duration == null || duration <= Duration.zero) {
      return l10n.timeNow;
    }

    if (duration.inDays > 0) {
      return l10n.timeDays(duration.inDays);
    }
    if (duration.inHours > 0) {
      return l10n.timeHours(duration.inHours);
    }
    if (duration.inMinutes > 0) {
      return l10n.timeMinutes(duration.inMinutes);
    }
    return l10n.timeNow;
  }

  /// セッション期限の警告レベルを取得
  static SessionWarningLevel getWarningLevel(Duration? timeRemaining) {
    if (timeRemaining == null || timeRemaining <= Duration.zero) {
      return SessionWarningLevel.expired;
    }
    if (timeRemaining.inHours < 1) {
      return SessionWarningLevel.critical;
    }
    if (timeRemaining.inDays < 1) {
      return SessionWarningLevel.warning;
    }
    return SessionWarningLevel.normal;
  }

  /// セッション状態を作成
  static SessionStatus createSessionStatus(DateTime? tokenExpiry) {
    final timeRemaining = getTimeRemaining(tokenExpiry);
    final warningLevel = getWarningLevel(timeRemaining);
    
    return SessionStatus(
      timeRemaining: timeRemaining,
      warningLevel: warningLevel,
      lastChecked: DateTime.now(),
    );
  }

  /// 警告レベルに応じたアイコンを取得
  static IconData getWarningIcon(SessionWarningLevel level) {
    switch (level) {
      case SessionWarningLevel.normal:
        return Icons.check_circle;
      case SessionWarningLevel.warning:
        return Icons.warning;
      case SessionWarningLevel.critical:
        return Icons.error;
      case SessionWarningLevel.expired:
        return Icons.error_outline;
    }
  }

  /// 警告レベルに応じた色を取得
  static Color getWarningColor(SessionWarningLevel level, ColorScheme colorScheme) {
    switch (level) {
      case SessionWarningLevel.normal:
        return colorScheme.primary;
      case SessionWarningLevel.warning:
        return colorScheme.tertiary;
      case SessionWarningLevel.critical:
        return colorScheme.error;
      case SessionWarningLevel.expired:
        return colorScheme.error;
    }
  }

  /// セッション期限が近いかチェック
  static bool isSessionExpiringSoon(Duration? timeRemaining) {
    if (timeRemaining == null) return true;
    return timeRemaining.inDays < 1;
  }

  /// セッション期限が切れているかチェック
  static bool isSessionExpired(DateTime? tokenExpiry) {
    if (tokenExpiry == null) return true;
    return tokenExpiry.isBefore(DateTime.now());
  }

  /// 次の警告時刻を計算
  static DateTime? getNextWarningTime(DateTime? tokenExpiry) {
    if (tokenExpiry == null) return null;
    
    final now = DateTime.now();
    final oneDayBefore = tokenExpiry.subtract(const Duration(days: 1));
    final oneHourBefore = tokenExpiry.subtract(const Duration(hours: 1));
    
    if (now.isBefore(oneDayBefore)) {
      return oneDayBefore;
    } else if (now.isBefore(oneHourBefore)) {
      return oneHourBefore;
    }
    
    return null;
  }
}