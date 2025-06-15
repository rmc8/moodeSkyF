// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:atproto_core/atproto_core.dart' as atcore;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Project imports:
import 'package:moodesky/services/bluesky/services/auth_service.dart';
import 'package:moodesky/services/bluesky/services/profile_service.dart';
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/shared/models/auth_models.dart';

/// Timeline response containing feed data and cursor for pagination
class TimelineResponse {
  final List<bsky.FeedView> feed;
  final String? cursor;

  const TimelineResponse({
    required this.feed,
    this.cursor,
  });
}

/// BlueskyServiceV2 - AT Protocol integrated service for MoodeSky
/// 
/// This service provides a complete interface for AT Protocol operations
/// including authentication, account management, and API interactions.
/// 
/// Features:
/// - Multi-account management
/// - App Password authentication
/// - Session management with secure storage
/// - Database integration for persistent storage
class BlueskyServiceV2 {
  final AppDatabase database;
  final FlutterSecureStorage secureStorage;
  final AuthConfig authConfig;
  
  // Service modules
  late final AuthService auth;
  late final ProfileService profile;
  
  BlueskyServiceV2({
    required this.database,
    required this.secureStorage,
    required this.authConfig,
  }) {
    // Initialize service modules
    auth = AuthService(
      database: database,
      secureStorage: secureStorage,
      authConfig: authConfig,
    );
    profile = ProfileService(
      database: database,
    );
  }

  /// Initialize the service
  /// This should be called before using any service functionality
  Future<void> initialize() async {
    try {
      await auth.initialize();
      debugPrint('BlueskyServiceV2 initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize BlueskyServiceV2: $e');
      rethrow;
    }
  }

  /// Get the currently active account
  Future<Account?> getActiveAccount() async {
    try {
      return await database.accountDao.getActiveAccount();
    } catch (e) {
      debugPrint('Failed to get active account: $e');
      return null;
    }
  }

  /// Get all accounts
  Future<List<Account>> getAllAccounts() async {
    try {
      return await database.accountDao.getAllAccounts();
    } catch (e) {
      debugPrint('Failed to get all accounts: $e');
      return [];
    }
  }

  /// Switch to a different account
  Future<void> switchAccount(String targetAccountDid) async {
    try {
      await database.accountDao.setActiveAccount(targetAccountDid);
      debugPrint('Switched to account: $targetAccountDid');
    } catch (e) {
      debugPrint('Failed to switch account: $e');
      rethrow;
    }
  }

  /// Sign out the current account
  Future<void> signOut() async {
    try {
      final activeAccount = await getActiveAccount();
      if (activeAccount != null) {
        await auth.signOut(activeAccount.did);
      }
    } catch (e) {
      debugPrint('Failed to sign out: $e');
      rethrow;
    }
  }

  /// Sign out all accounts
  Future<void> signOutAll() async {
    try {
      await auth.signOutAll();
      debugPrint('Signed out all accounts');
    } catch (e) {
      debugPrint('Failed to sign out all accounts: $e');
      rethrow;
    }
  }

  /// Remove an account
  Future<void> removeAccount(String accountDid) async {
    try {
      await auth.removeAccount(accountDid);
      debugPrint('Removed account: $accountDid');
    } catch (e) {
      debugPrint('Failed to remove account: $e');
      rethrow;
    }
  }

  /// Get timeline for a specific account with cursor support for pagination
  Future<TimelineResponse> getTimelineFeed({
    required String accountDid,
    String? cursor,
    int limit = 50,
  }) async {
    final startTime = DateTime.now();
    
    try {
      final result = await _executeWithTokenRefresh(accountDid, (client) async {
        debugPrint('BlueskyService: Fetching timeline (limit: $limit, cursor: $cursor)');
        
        final apiStartTime = DateTime.now();
        final response = await client.feed.getTimeline(
          limit: limit,
          cursor: cursor,
        );
        final apiEndTime = DateTime.now();
        final apiDuration = apiEndTime.difference(apiStartTime);

        debugPrint('BlueskyService: Timeline API response received: ${response.data.feed.length} posts, cursor: ${response.data.cursor}');
        debugPrint('⚡ BlueskyService API call duration: ${apiDuration.inMilliseconds}ms');
        
        return TimelineResponse(
          feed: response.data.feed,
          cursor: response.data.cursor,
        );
      });
      
      final totalDuration = DateTime.now().difference(startTime);
      debugPrint('⚡ BlueskyService total operation duration: ${totalDuration.inMilliseconds}ms');
      
      return result;
    } catch (e) {
      final errorDuration = DateTime.now().difference(startTime);
      debugPrint('❌ BlueskyService operation failed after ${errorDuration.inMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Execute API call with automatic token refresh on expiration
  Future<T> _executeWithTokenRefresh<T>(
    String accountDid,
    Future<T> Function(bsky.Bluesky client) apiCall,
  ) async {
    // Get account and create client
    var account = await database.accountDao.getAccountByDid(accountDid);
    if (account == null) {
      throw Exception('Account not found: $accountDid');
    }

    if (account.accessJwt == null) {
      throw Exception('No access token for account: ${account.handle}');
    }

    try {
      // Create Bluesky client with account's session
      final session = atcore.Session(
        did: account.did,
        handle: account.handle,
        accessJwt: account.accessJwt!,
        refreshJwt: account.refreshJwt ?? '',
      );

      final client = bsky.Bluesky.fromSession(session);
      
      // Try API call
      return await apiCall(client);
    } catch (e) {
      final errorString = e.toString();
      
      // Check for various token-related errors
      if (_isTokenError(errorString)) {
        debugPrint('BlueskyService: Token error detected for ${account.handle}: $errorString');
        
        // Attempt token refresh
        final refreshResult = await auth.refreshSession(account.did);
        
        if (refreshResult != null) {
          debugPrint('BlueskyService: Token refreshed successfully for ${account.handle}');
          
          // Get updated account after refresh
          account = await database.accountDao.getAccountByDid(accountDid);
          if (account?.accessJwt != null) {
            // Create new client with refreshed token
            final newSession = atcore.Session(
              did: account!.did,
              handle: account.handle,
              accessJwt: account.accessJwt!,
              refreshJwt: account.refreshJwt ?? '',
            );

            final newClient = bsky.Bluesky.fromSession(newSession);
            
            // Retry API call with new token
            return await apiCall(newClient);
          }
        }
        
        debugPrint('BlueskyService: Token refresh failed for ${account?.handle}');
        
        // Determine specific error type for better user feedback
        if (_isTokenVerificationError(errorString)) {
          throw Exception('Token could not be verified. Please sign in again.');
        } else {
          throw Exception('Session expired and refresh failed');
        }
      }
      
      // Re-throw non-token related errors
      rethrow;
    }
  }

  /// Check if error is related to token issues
  bool _isTokenError(String errorString) {
    final lowerString = errorString.toLowerCase();
    return lowerString.contains('token has expired') ||
           lowerString.contains('expiredtoken') ||
           lowerString.contains('invalidtoken') ||
           lowerString.contains('token could not be verified') ||
           lowerString.contains('tokenvalidationfailed') ||
           lowerString.contains('invalidsignature') ||
           lowerString.contains('unauthorized') ||
           lowerString.contains('token is invalid') ||
           lowerString.contains('authentication failed');
  }

  /// Check if error is specifically related to token verification
  bool _isTokenVerificationError(String errorString) {
    final lowerString = errorString.toLowerCase();
    return lowerString.contains('token could not be verified') ||
           lowerString.contains('tokenvalidationfailed') ||
           lowerString.contains('invalidsignature') ||
           lowerString.contains('token verification failed');
  }

  /// プロフィール情報を取得してデータベースに保存
  /// 
  /// [accountDid] - プロフィールを取得するアカウントのDID
  /// 
  /// Returns: 成功時true、失敗時false
  Future<bool> fetchAndUpdateProfile(String accountDid) async {
    try {
      debugPrint('🔄 [SERVICE] Starting profile fetch for account: ${accountDid.substring(0, 20)}...');
      
      return await _executeWithTokenRefresh(accountDid, (client) async {
        return await profile.fetchAndUpdateProfile(
          client: client,
          did: accountDid,
        );
      });
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to fetch and update profile for $accountDid: $e');
      return false;
    }
  }

  /// 全アカウントのプロフィール情報を一括更新
  /// 
  /// Returns: 成功したアカウント数
  Future<int> fetchAndUpdateAllProfiles() async {
    try {
      debugPrint('🔄 [SERVICE] Starting bulk profile update for all accounts');
      
      final accounts = await getAllAccounts();
      if (accounts.isEmpty) {
        debugPrint('⚠️ [SERVICE] No accounts found for profile update');
        return 0;
      }

      int successCount = 0;
      
      for (final account in accounts) {
        try {
          final success = await fetchAndUpdateProfile(account.did);
          if (success) {
            successCount++;
          }
          
          // API負荷軽減のため間隔を空ける
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('❌ [SERVICE] Error updating profile for ${account.handle}: $e');
        }
      }
      
      debugPrint('✅ [SERVICE] Bulk profile update complete: $successCount/${accounts.length} accounts updated');
      return successCount;
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to perform bulk profile update: $e');
      return 0;
    }
  }

  /// 指定されたアカウントのプロフィール情報を取得（データベース更新なし）
  /// 
  /// [accountDid] - プロフィールを取得するアカウントのDID
  /// 
  /// Returns: ProfileInfo または null（取得失敗時）
  Future<ProfileInfo?> getProfile(String accountDid) async {
    try {
      debugPrint('🔍 [SERVICE] Fetching profile info for account: ${accountDid.substring(0, 20)}...');
      
      return await _executeWithTokenRefresh(accountDid, (client) async {
        return await profile.getProfile(
          client: client,
          did: accountDid,
        );
      });
    } catch (e) {
      debugPrint('❌ [SERVICE] Failed to get profile for $accountDid: $e');
      return null;
    }
  }
}