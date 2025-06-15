// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Part files
part 'session_models.freezed.dart';

/// セッション警告レベル
enum SessionWarningLevel {
  /// 正常（1日以上残り）
  normal,
  /// 警告（1日以下）
  warning,
  /// 緊急（1時間以下）
  critical,
  /// 期限切れ
  expired,
}

/// セッション状態
@freezed
class SessionStatus with _$SessionStatus {
  const factory SessionStatus({
    /// 残り時間
    Duration? timeRemaining,
    /// 警告レベル
    required SessionWarningLevel warningLevel,
    /// 最後のチェック時刻
    DateTime? lastChecked,
  }) = _SessionStatus;
}

/// セッション情報
@freezed
class SessionInfo with _$SessionInfo {
  const factory SessionInfo({
    /// アカウントDID
    required String did,
    /// セッション状態
    required SessionStatus status,
    /// 再認証が必要かどうか
    required bool needsReauth,
    /// セッション期限
    DateTime? tokenExpiry,
  }) = _SessionInfo;
}