// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/providers/database_provider.dart';
import 'package:moodesky/core/utils/session_utils.dart';
import 'package:moodesky/shared/models/session_models.dart';

part 'session_provider.g.dart';

/// セッション情報プロバイダー
@riverpod
class SessionInfoNotifier extends _$SessionInfoNotifier {
  @override
  Map<String, SessionInfo> build() {
    // 初期化時に非同期でセッション情報を読み込む
    Future.microtask(() async {
      debugPrint('🔄 [SESSION] SessionInfoNotifier initializing, auto-refreshing sessions');
      await refreshAllSessions();
    });
    return {};
  }

  /// 全アカウントのセッション情報を更新
  Future<void> refreshAllSessions() async {
    debugPrint('🔍 [SESSION] SessionProvider.refreshAllSessions called');
    final accounts = ref.read(availableAccountsProvider);
    debugPrint('🔍 [SESSION] Available accounts count: ${accounts.length}');
    
    if (accounts.isEmpty) {
      debugPrint('🔍 [SESSION] No accounts available, clearing session state');
      state = {};
      return;
    }

    final database = ref.read(databaseProvider);
    final Map<String, SessionInfo> newState = {};

    for (final account in accounts) {
      try {
        debugPrint('🔍 [SESSION] Processing account: ${account.handle} (${account.did.substring(0, 20)}...)');
        
        // データベースからアカウント情報を取得
        final dbAccount = await database.accountDao.getAccountByDid(account.did);
        if (dbAccount != null) {
          debugPrint('🔍 [SESSION] Account ${account.handle}: refreshJWT expiry from DB = ${dbAccount.tokenExpiry}');
          
          if (dbAccount.tokenExpiry != null) {
            final now = DateTime.now();
            final timeUntilExpiry = dbAccount.tokenExpiry!.difference(now);
            debugPrint('🔍 [SESSION] Account ${account.handle}: Time until expiry = ${timeUntilExpiry.inDays} days, ${timeUntilExpiry.inHours % 24} hours');
          } else {
            debugPrint('⚠️ [SESSION] Account ${account.handle}: tokenExpiry is NULL in database');
          }
          
          final sessionStatus = SessionUtils.createSessionStatus(dbAccount.tokenExpiry);
          final needsReauth = SessionUtils.isSessionExpired(dbAccount.tokenExpiry) ||
                             SessionUtils.isSessionExpiringSoon(sessionStatus.timeRemaining);
          
          debugPrint('🔍 [SESSION] Account ${account.handle}: timeRemaining=${sessionStatus.timeRemaining}, warningLevel=${sessionStatus.warningLevel}, needsReauth=$needsReauth');
          
          newState[account.did] = SessionInfo(
            did: account.did,
            status: sessionStatus,
            needsReauth: needsReauth,
            tokenExpiry: dbAccount.tokenExpiry,
          );
        } else {
          debugPrint('⚠️ [SESSION] No database record found for account ${account.handle} (${account.did.substring(0, 20)}...)');
          // データベースにレコードがない場合は期限切れとして扱う
          newState[account.did] = SessionInfo(
            did: account.did,
            status: SessionUtils.createSessionStatus(null),
            needsReauth: true,
            tokenExpiry: null,
          );
        }
      } catch (e) {
        debugPrint('❌ [SESSION] Error processing account ${account.handle}: $e');
        // エラーの場合は期限切れとして扱う
        newState[account.did] = SessionInfo(
          did: account.did,
          status: SessionUtils.createSessionStatus(null),
          needsReauth: true,
          tokenExpiry: null,
        );
      }
    }

    debugPrint('✅ [SESSION] Session state updated for ${newState.length} accounts');
    for (final entry in newState.entries) {
      final info = entry.value;
      debugPrint('   Account ${entry.key.substring(0, 20)}...: timeRemaining=${info.status.timeRemaining}, needsReauth=${info.needsReauth}');
    }
    
    state = newState;
  }

  /// 特定のアカウントのセッション情報を更新
  Future<void> refreshSessionForAccount(String did) async {
    debugPrint('🔄 [SESSION] refreshSessionForAccount called for $did');
    final database = ref.read(databaseProvider);

    try {
      final dbAccount = await database.accountDao.getAccountByDid(did);
      if (dbAccount != null) {
        debugPrint('🔍 [SESSION] Account $did found in DB: tokenExpiry=${dbAccount.tokenExpiry}');
        
        if (dbAccount.tokenExpiry != null) {
          final now = DateTime.now();
          final timeUntilExpiry = dbAccount.tokenExpiry!.difference(now);
          debugPrint('🔍 [SESSION] Account $did: Time until expiry = ${timeUntilExpiry.inDays} days, ${timeUntilExpiry.inHours % 24} hours');
        } else {
          debugPrint('⚠️ [SESSION] Account $did: tokenExpiry is NULL in database');
        }
        
        final sessionStatus = SessionUtils.createSessionStatus(dbAccount.tokenExpiry);
        final needsReauth = SessionUtils.isSessionExpired(dbAccount.tokenExpiry) ||
                           SessionUtils.isSessionExpiringSoon(sessionStatus.timeRemaining);
        
        debugPrint('🔍 [SESSION] Account $did: timeRemaining=${sessionStatus.timeRemaining}, warningLevel=${sessionStatus.warningLevel}, needsReauth=$needsReauth');
        
        state = {
          ...state,
          did: SessionInfo(
            did: did,
            status: sessionStatus,
            needsReauth: needsReauth,
            tokenExpiry: dbAccount.tokenExpiry,
          ),
        };
        
        debugPrint('✅ [SESSION] Session info updated for account $did');
      } else {
        debugPrint('⚠️ [SESSION] Account $did not found in database');
        // データベースにレコードがない場合は期限切れとして扱う
        state = {
          ...state,
          did: SessionInfo(
            did: did,
            status: SessionUtils.createSessionStatus(null),
            needsReauth: true,
            tokenExpiry: null,
          ),
        };
      }
    } catch (e) {
      debugPrint('❌ [SESSION] Error refreshing session for account $did: $e');
      // エラーの場合は期限切れとして扱う
      state = {
        ...state,
        did: SessionInfo(
          did: did,
          status: SessionUtils.createSessionStatus(null),
          needsReauth: true,
          tokenExpiry: null,
        ),
      };
    }
  }

  /// セッション期限を更新
  Future<void> updateTokenExpiry(String did, DateTime? tokenExpiry) async {
    debugPrint('🔍 [DEBUG] SessionProvider.updateTokenExpiry called for $did with expiry: $tokenExpiry');
    final database = ref.read(databaseProvider);

    try {
      // データベースを更新
      await database.accountDao.updateAccountTokenExpiry(did, tokenExpiry);
      debugPrint('🔍 [DEBUG] Database updated successfully');
      
      // プロバイダーの状態を更新
      await refreshSessionForAccount(did);
      debugPrint('🔍 [DEBUG] Session provider state refreshed');
    } catch (e) {
      debugPrint('❌ [DEBUG] Error in updateTokenExpiry: $e');
    }
  }
}

/// 特定のアカウントのセッション情報を取得
@riverpod
Future<SessionInfo?> sessionInfo(Ref ref, String did) async {
  final sessions = ref.watch(sessionInfoNotifierProvider);
  final result = sessions[did];
  
  // セッション情報がない場合、同期的に取得
  if (result == null) {
    debugPrint('⚠️ [SESSION] sessionInfo for $did is null, refreshing synchronously');
    
    try {
      final notifier = ref.read(sessionInfoNotifierProvider.notifier);
      await notifier.refreshSessionForAccount(did);
      
      // 更新後の状態を再取得
      final updatedSessions = ref.read(sessionInfoNotifierProvider);
      final updatedResult = updatedSessions[did];
      
      debugPrint('✅ [SESSION] sessionInfo for $did refreshed: ${updatedResult != null ? "found" : "still null"}');
      return updatedResult;
    } catch (e) {
      debugPrint('❌ [SESSION] Failed to refresh sessionInfo for $did: $e');
      return null;
    }
  } else {
    debugPrint('✅ [SESSION] sessionInfo for $did found: timeRemaining=${result.status.timeRemaining}, needsReauth=${result.needsReauth}');
    return result;
  }
}

/// セッション期限が近いアカウントのリストを取得
@riverpod
List<String> accountsNeedingReauth(Ref ref) {
  final sessions = ref.watch(sessionInfoNotifierProvider);
  return sessions.entries
      .where((entry) => entry.value.needsReauth)
      .map((entry) => entry.key)
      .toList();
}

/// セッション状態の統計を取得
@riverpod
SessionStatistics sessionStatistics(Ref ref) {
  final sessions = ref.watch(sessionInfoNotifierProvider);
  
  int normal = 0;
  int warning = 0;
  int critical = 0;
  int expired = 0;
  
  for (final session in sessions.values) {
    switch (session.status.warningLevel) {
      case SessionWarningLevel.normal:
        normal++;
        break;
      case SessionWarningLevel.warning:
        warning++;
        break;
      case SessionWarningLevel.critical:
        critical++;
        break;
      case SessionWarningLevel.expired:
        expired++;
        break;
    }
  }
  
  return SessionStatistics(
    total: sessions.length,
    normal: normal,
    warning: warning,
    critical: critical,
    expired: expired,
  );
}

/// セッション統計
class SessionStatistics {
  const SessionStatistics({
    required this.total,
    required this.normal,
    required this.warning,
    required this.critical,
    required this.expired,
  });

  final int total;
  final int normal;
  final int warning;
  final int critical;
  final int expired;
}