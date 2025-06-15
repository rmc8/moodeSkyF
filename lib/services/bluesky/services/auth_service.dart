// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:atproto/atproto.dart' as atproto;
import 'package:atproto_core/atproto_core.dart' as atcore;
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Project imports:
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/shared/models/auth_models.dart';
import 'dart:convert';

/// AuthService - Authentication service for AT Protocol
/// 
/// Handles authentication operations including:
/// - App Password authentication
/// - Session management
/// - Token storage and retrieval
/// - Account management
class AuthService {
  final AppDatabase database;
  final FlutterSecureStorage secureStorage;
  final AuthConfig authConfig;

  AuthService({
    required this.database,
    required this.secureStorage,
    required this.authConfig,
  });

  /// Initialize the authentication service
  Future<void> initialize() async {
    try {
      // TODO: Implement initialization logic
      debugPrint('AuthService initialized');
    } catch (e) {
      debugPrint('Failed to initialize AuthService: $e');
      rethrow;
    }
  }

  /// Sign in with app password
  Future<AuthResult> signInWithAppPassword({
    required String identifier,
    required String password,
    String? pdsHost,
    bool isAdditionalAccount = false,
  }) async {
    try {
      debugPrint('🔐 Attempting app password sign in for: $identifier');
      debugPrint('   PDS Host: ${pdsHost ?? authConfig.defaultPdsHost}');
      
      // 実際のAT Protocol認証を実行
      final sessionResponse = await atproto.createSession(
        identifier: identifier,
        password: password,
        service: pdsHost ?? authConfig.defaultPdsHost,
      );

      final sessionData = sessionResponse.data;
      debugPrint('✅ Authentication successful for: ${sessionData.handle}');
      debugPrint('   DID: ${sessionData.did}');
      debugPrint('   Email: ${sessionData.email ?? 'N/A'}');

      // セッションデータを作成
      final appPasswordSession = AppPasswordSessionData(
        accessJwt: sessionData.accessJwt,
        refreshJwt: sessionData.refreshJwt,
        did: sessionData.did,
        handle: sessionData.handle,
        email: sessionData.email,
        sessionString: null,
      );

      // ユーザープロフィールを作成
      final profile = UserProfile(
        did: sessionData.did,
        handle: sessionData.handle,
        displayName: sessionData.handle, // 初期値としてhandleを使用
        description: null,
        avatar: null,
        banner: null,
        email: sessionData.email,
        isVerified: false,
      );

      final authSessionData = AuthSessionData.appPassword(
        appPasswordSession: appPasswordSession,
        profile: profile,
      );

      // atproto.dart Session オブジェクトを作成してJWT有効期限を取得
      final session = atcore.Session(
        did: sessionData.did,
        handle: sessionData.handle,
        accessJwt: sessionData.accessJwt,
        refreshJwt: sessionData.refreshJwt,
      );
      
      final tokenExpiry = _getSessionExpiry(session);
      debugPrint('🔍 [AUTH] Initial login - RefreshJWT expiry extracted: $tokenExpiry');
      
      // アカウント情報をデータベースに保存
      await _storeAccount(appPasswordSession, profile, isAdditionalAccount, tokenExpiry);

      debugPrint('✅ Account stored successfully in database');
      
      // セッションプロバイダーの状態を更新
      // Note: プロバイダーはcontainerが利用可能な場合のみ更新
      debugPrint('🔍 [DEBUG] Session stored, provider will be updated automatically');

      return AuthResult.success(
        session: authSessionData,
        accountDid: appPasswordSession.did,
      );
    } catch (e) {
      debugPrint('❌ App password sign in failed: $e');
      
      // エラータイプを詳細に分析
      final errorType = _detectErrorType(e.toString());
      final errorMessage = _createUserFriendlyErrorMessage(e.toString(), errorType);
      
      debugPrint('   Error type: $errorType');
      debugPrint('   User message: $errorMessage');
      
      return AuthResult.failure(
        error: errorMessage,
        errorDescription: e.toString(),
        errorType: errorType,
      );
    }
  }

  /// エラータイプを自動検出
  AuthErrorType _detectErrorType(String errorMessage) {
    final lowercaseError = errorMessage.toLowerCase();
    
    // トークン検証関連エラー
    if (lowercaseError.contains('token could not be verified') ||
        lowercaseError.contains('invalid token') ||
        lowercaseError.contains('expired token') ||
        lowercaseError.contains('token verification failed')) {
      return AuthErrorType.tokenVerificationFailed;
    }
    
    // 認証情報エラー
    if (lowercaseError.contains('invalid credentials') ||
        lowercaseError.contains('invalid identifier') ||
        lowercaseError.contains('invalid password') ||
        lowercaseError.contains('authentication failed')) {
      return AuthErrorType.invalidCredentials;
    }
    
    // ネットワークエラー
    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('timeout')) {
      return AuthErrorType.networkError;
    }
    
    // サーバーエラー
    if (lowercaseError.contains('server error') ||
        lowercaseError.contains('internal error')) {
      return AuthErrorType.serverError;
    }
    
    return AuthErrorType.unknownError;
  }

  /// ユーザー向けのエラーメッセージを作成
  String _createUserFriendlyErrorMessage(String originalError, AuthErrorType errorType) {
    switch (errorType) {
      case AuthErrorType.tokenVerificationFailed:
        return 'トークンの検証に失敗しました。再度ログインしてください。';
      case AuthErrorType.invalidCredentials:
        return 'ユーザー名またはアプリパスワードが正しくありません。';
      case AuthErrorType.networkError:
        return 'ネットワークエラーが発生しました。接続を確認してください。';
      case AuthErrorType.serverError:
        return 'サーバーエラーが発生しました。しばらく後に再試行してください。';
      default:
        return '認証に失敗しました。入力内容を確認してください。';
    }
  }

  /// Store account information in database
  Future<void> _storeAccount(
    AppPasswordSessionData sessionData,
    UserProfile profile,
    bool isAdditionalAccount,
    DateTime? tokenExpiry,
  ) async {
    try {
      await database.accountDao.upsertAccountByDid(
        AccountsCompanion.insert(
          did: sessionData.did,
          handle: sessionData.handle,
          displayName: Value(profile.displayName),
          description: Value(profile.description),
          avatar: Value(profile.avatar),
          banner: Value(profile.banner),
          email: Value(profile.email),
          accessJwt: Value(sessionData.accessJwt),
          refreshJwt: Value(sessionData.refreshJwt),
          sessionString: Value(sessionData.sessionString),
          pdsUrl: authConfig.defaultPdsHost,
          loginMethod: const Value('app_password'),
          tokenExpiry: Value(tokenExpiry),
          isActive: Value(!isAdditionalAccount), // Set as active if not additional
          lastUsed: Value(DateTime.now()),
        ),
      );
      
      debugPrint('Account stored successfully: ${sessionData.did}');
      if (tokenExpiry != null) {
        debugPrint('✅ [AUTH] RefreshJWT expires at: $tokenExpiry');
        debugPrint('✅ [AUTH] Re-authentication needed in: ${tokenExpiry.difference(DateTime.now()).inDays} days');
      } else {
        debugPrint('⚠️ [AUTH] RefreshJWT expiry is null - will show "now" to user');
      }
    } catch (e) {
      debugPrint('Failed to store account: $e');
      rethrow;
    }
  }

  /// Sign out a specific account
  Future<void> signOut(String accountDid) async {
    try {
      // Clear tokens from secure storage
      await secureStorage.delete(key: 'access_token_$accountDid');
      await secureStorage.delete(key: 'refresh_token_$accountDid');
      
      // Update account status in database
      await database.accountDao.clearAccountSession(accountDid);
      
      debugPrint('Signed out account: $accountDid');
    } catch (e) {
      debugPrint('Failed to sign out account: $e');
      rethrow;
    }
  }

  /// Sign out all accounts
  Future<void> signOutAll() async {
    try {
      final accounts = await database.accountDao.getAllAccounts();
      
      for (final account in accounts) {
        await signOut(account.did);
      }
      
      // Clear all secure storage
      await secureStorage.deleteAll();
      
      debugPrint('Signed out all accounts');
    } catch (e) {
      debugPrint('Failed to sign out all accounts: $e');
      rethrow;
    }
  }

  /// Remove an account
  Future<void> removeAccount(String accountDid) async {
    try {
      // Sign out first
      await signOut(accountDid);
      
      // Remove from database
      await database.accountDao.deleteAccount(accountDid);
      
      debugPrint('Removed account: $accountDid');
    } catch (e) {
      debugPrint('Failed to remove account: $e');
      rethrow;
    }
  }

  /// Refresh session for a specific account
  Future<AppPasswordSessionData?> refreshSession(String accountDid) async {
    try {
      final account = await database.accountDao.getAccountByDid(accountDid);
      if (account == null) {
        debugPrint('Account not found for refresh: $accountDid');
        return null;
      }

      if (account.refreshJwt == null) {
        debugPrint('No refresh token available for account: ${account.handle}');
        return null;
      }

      debugPrint('Attempting token refresh for account: ${account.handle}');
      
      // Call AT Protocol refresh session endpoint
      final refreshResponse = await atproto.refreshSession(
        refreshJwt: account.refreshJwt!,
        service: authConfig.defaultPdsHost,
      );
      
      final refreshedSession = refreshResponse.data;
      if (refreshedSession.accessJwt.isEmpty || refreshedSession.refreshJwt.isEmpty) {
        debugPrint('Token refresh failed: Invalid response tokens');
        return null;
      }
      
      final newSessionData = AppPasswordSessionData(
        accessJwt: refreshedSession.accessJwt,
        refreshJwt: refreshedSession.refreshJwt,
        did: account.did,
        handle: account.handle,
        email: account.email,
        sessionString: account.sessionString,
      );

      // Update token expiry with new session expiry
      final session = atcore.Session(
        did: account.did,
        handle: account.handle,
        accessJwt: refreshedSession.accessJwt,
        refreshJwt: refreshedSession.refreshJwt,
      );
      
      final tokenExpiry = _getSessionExpiry(session);

      // Update account in database with new tokens and expiry in single operation
      await database.accountDao.updateAccountWithAppPasswordSession(
        did: accountDid,
        accessJwt: newSessionData.accessJwt,
        refreshJwt: newSessionData.refreshJwt,
        sessionString: newSessionData.sessionString ?? '',
        tokenExpiry: tokenExpiry,
      );
      
      if (tokenExpiry != null) {
        debugPrint('Updated token expiry to: $tokenExpiry');
      }

      debugPrint('Token refresh successful for account: ${account.handle}');
      
      // セッション更新成功時にプロフィール情報も更新
      debugPrint('🔄 [AUTH] Updating profile information after session refresh');
      await _updateProfileAfterRefresh(accountDid);
      
      return newSessionData;
    } catch (e) {
      debugPrint('Failed to refresh session for $accountDid: $e');
      
      // Handle specific refresh token failure cases
      final errorString = e.toString();
      if (errorString.contains('RefreshTokenExpired') || 
          errorString.contains('InvalidRefreshToken') ||
          errorString.contains('TokenRevoked') ||
          errorString.contains('Token could not be verified') ||
          errorString.contains('TokenValidationFailed') ||
          errorString.contains('InvalidSignature')) {
        debugPrint('Refresh token expired/invalid/unverifiable for $accountDid, clearing session');
        // Clear the account session since refresh token is invalid or unverifiable
        await database.accountDao.clearAccountSession(accountDid);
      }
      
      return null;
    }
  }

  /// Validate if a session/token is still valid
  /// Returns true if valid, false if invalid
  Future<bool> validateSession(String accountDid) async {
    try {
      final account = await database.accountDao.getAccountByDid(accountDid);
      if (account == null) {
        debugPrint('❌ Account not found for validation: $accountDid');
        return false;
      }

      if (account.accessJwt == null) {
        debugPrint('❌ No access token available for validation: ${account.handle}');
        return false;
      }

      debugPrint('🔐 Validating session for account: ${account.handle}');
      
      // 実際のAT Protocol APIを使用してセッション検証
      try {
        // ATProtoクライアントでセッション検証を実行
        final session = atcore.Session(
          did: account.did,
          handle: account.handle,
          accessJwt: account.accessJwt!,
          refreshJwt: account.refreshJwt ?? '',
        );

        final client = atproto.ATProto.fromSession(session);
        final sessionResponse = await client.server.getSession();
        
        final sessionData = sessionResponse.data;
        debugPrint('✅ Session validation successful for: ${sessionData.handle}');
        debugPrint('   DID: ${sessionData.did}');
        debugPrint('   Active: ${sessionData.active}');
        
        return true;
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();
        
        if (errorMessage.contains('token could not be verified') ||
            errorMessage.contains('invalid token') ||
            errorMessage.contains('expired token')) {
          debugPrint('❌ Token verification failed for ${account.handle}: $e');
          debugPrint('   This indicates the token has expired or is invalid');
          return false;
        }
        
        if (errorMessage.contains('unauthorized') ||
            errorMessage.contains('forbidden')) {
          debugPrint('❌ Authorization failed for ${account.handle}: $e');
          return false;
        }
        
        // その他のエラーの場合、ネットワークエラーの可能性があるため
        // 一時的な問題として有効とみなす（ただしログに記録）
        debugPrint('⚠️ Session validation inconclusive for ${account.handle}: $e');
        debugPrint('   Treating as valid due to potential network issues');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Session validation failed for $accountDid: $e');
      return false;
    }
  }

  /// Clear invalid sessions automatically
  Future<void> clearInvalidSessions() async {
    try {
      final accounts = await database.accountDao.getAllAccounts();
      
      for (final account in accounts) {
        final isValid = await validateSession(account.did);
        if (!isValid && account.accessJwt != null) {
          debugPrint('Clearing invalid session for account: ${account.handle}');
          await database.accountDao.clearAccountSession(account.did);
        }
      }
    } catch (e) {
      debugPrint('Failed to clear invalid sessions: $e');
    }
  }

  /// Re-authenticate an existing account
  /// This method requires the user to provide their password again
  Future<AuthResult> reauthenticateAccount({
    required String accountDid,
    required String password,
  }) async {
    try {
      debugPrint('🔄 Attempting re-authentication for account: $accountDid');
      
      // Get existing account information
      final existingAccount = await database.accountDao.getAccountByDid(accountDid);
      if (existingAccount == null) {
        debugPrint('❌ Account not found for re-authentication: $accountDid');
        return AuthResult.failure(
          error: 'アカウントが見つかりません',
          errorType: AuthErrorType.unknownError,
        );
      }

      final identifier = existingAccount.handle;
      final pdsHost = existingAccount.pdsUrl;
      
      debugPrint('   Re-authenticating as: $identifier');
      debugPrint('   PDS Host: $pdsHost');

      // Perform authentication with existing account details
      final sessionResponse = await atproto.createSession(
        identifier: identifier,
        password: password,
        service: pdsHost,
      );

      final sessionData = sessionResponse.data;
      debugPrint('✅ Re-authentication successful for: ${sessionData.handle}');
      debugPrint('   DID: ${sessionData.did}');

      // Verify the DID matches the existing account
      if (sessionData.did != accountDid) {
        debugPrint('❌ DID mismatch during re-authentication');
        debugPrint('   Expected: $accountDid');
        debugPrint('   Received: ${sessionData.did}');
        return AuthResult.failure(
          error: 'アカウント情報が一致しません',
          errorType: AuthErrorType.invalidCredentials,
        );
      }

      // Extract token expiry from new session first
      final session = atcore.Session(
        did: sessionData.did,
        handle: sessionData.handle,
        accessJwt: sessionData.accessJwt,
        refreshJwt: sessionData.refreshJwt,
      );
      
      final tokenExpiry = _getSessionExpiry(session);
      
      // Update account session with token expiry in single operation
      await database.accountDao.updateAccountWithAppPasswordSession(
        did: accountDid,
        accessJwt: sessionData.accessJwt,
        refreshJwt: sessionData.refreshJwt,
        sessionString: '',
        tokenExpiry: tokenExpiry,
      );
      
      if (tokenExpiry != null) {
        debugPrint('Updated token expiry to: $tokenExpiry');
        debugPrint('✅ [AUTH] Re-authentication successful - RefreshJWT valid for ${tokenExpiry.difference(DateTime.now()).inDays} days');
      }

      debugPrint('✅ Re-authentication complete, session updated in database');

      // Create session data for return
      final appPasswordSession = AppPasswordSessionData(
        accessJwt: sessionData.accessJwt,
        refreshJwt: sessionData.refreshJwt,
        did: sessionData.did,
        handle: sessionData.handle,
        email: sessionData.email,
        sessionString: '',
      );

      final profile = UserProfile(
        did: sessionData.did,
        handle: sessionData.handle,
        displayName: existingAccount.displayName,
        description: existingAccount.description,
        avatar: existingAccount.avatar,
        banner: existingAccount.banner,
        email: sessionData.email,
        isVerified: existingAccount.isVerified,
      );

      final authSessionData = AuthSessionData.appPassword(
        appPasswordSession: appPasswordSession,
        profile: profile,
      );

      return AuthResult.success(
        session: authSessionData,
        accountDid: accountDid,
      );
    } catch (e) {
      debugPrint('❌ Re-authentication failed for $accountDid: $e');
      
      final errorType = _detectErrorType(e.toString());
      final errorMessage = _createUserFriendlyErrorMessage(e.toString(), errorType);
      
      debugPrint('   Error type: $errorType');
      debugPrint('   User message: $errorMessage');
      
      return AuthResult.failure(
        error: errorMessage,
        errorDescription: e.toString(),
        errorType: errorType,
      );
    }
  }

  /// Try to refresh session automatically, fallback to re-authentication if needed
  Future<AuthResult> refreshOrReauthenticate({
    required String accountDid,
    String? password,
  }) async {
    try {
      debugPrint('🔄 Attempting automatic session refresh for: $accountDid');
      
      // First try to refresh using existing refresh token
      final refreshResult = await refreshSession(accountDid);
      if (refreshResult != null) {
        debugPrint('✅ Session refreshed successfully');
        
        // Update token expiry with new refresh session
        final existingAccount = await database.accountDao.getAccountByDid(accountDid);
        if (existingAccount != null) {
          final session = atcore.Session(
            did: existingAccount.did,
            handle: existingAccount.handle,
            accessJwt: refreshResult.accessJwt,
            refreshJwt: refreshResult.refreshJwt,
          );
          
          final tokenExpiry = _getSessionExpiry(session);
          if (tokenExpiry != null) {
            await database.accountDao.updateAccountTokenExpiry(accountDid, tokenExpiry);
            debugPrint('Updated token expiry to: $tokenExpiry');
          }
        }
        
        // プロフィール情報更新（refreshSessionで既に実行されているが念のため）
        debugPrint('🔄 [AUTH] Ensuring profile is updated after refresh');
        await _updateProfileAfterRefresh(accountDid);
        
        // Return success result
        final account = await database.accountDao.getAccountByDid(accountDid);
        if (account != null) {
          final profile = UserProfile(
            did: account.did,
            handle: account.handle,
            displayName: account.displayName,
            description: account.description,
            avatar: account.avatar,
            banner: account.banner,
            email: account.email,
            isVerified: account.isVerified,
          );

          final authSessionData = AuthSessionData.appPassword(
            appPasswordSession: refreshResult,
            profile: profile,
          );

          return AuthResult.success(
            session: authSessionData,
            accountDid: accountDid,
          );
        }
      }
      
      debugPrint('⚠️ Session refresh failed, re-authentication required');
      
      // If password is provided, attempt re-authentication
      if (password != null) {
        debugPrint('🔄 Attempting re-authentication with provided password');
        return await reauthenticateAccount(
          accountDid: accountDid,
          password: password,
        );
      }
      
      // If no password provided, return failure requiring re-authentication
      return AuthResult.failure(
        error: 'セッションの更新に失敗しました。再度ログインしてください。',
        errorType: AuthErrorType.tokenExpired,
      );
    } catch (e) {
      debugPrint('❌ Refresh or re-authentication failed for $accountDid: $e');
      
      final errorType = _detectErrorType(e.toString());
      final errorMessage = _createUserFriendlyErrorMessage(e.toString(), errorType);
      
      return AuthResult.failure(
        error: errorMessage,
        errorDescription: e.toString(),
        errorType: errorType,
      );
    }
  }

  /// RefreshJwt から再認証期限を取得（ユーザー向け期限）
  DateTime? _getSessionExpiry(atcore.Session session) {
    try {
      debugPrint('🔍 [AUTH] Getting refresh token expiry using Bluesky library');
      
      // Blueskyライブラリの内蔵Jwt機能を活用
      final refreshJwt = session.refreshTokenJwt;
      
      // Jwt.isExpiredで期限切れチェック
      if (refreshJwt.isExpired) {
        debugPrint('⚠️ [AUTH] RefreshJWT has already expired');
        return null; // 既に期限切れ
      }
      
      // Jwt.expで直接有効期限を取得
      final expiry = refreshJwt.exp;
      debugPrint('✅ [AUTH] RefreshJWT expiry: $expiry');
      
      final timeUntilExpiry = expiry.difference(DateTime.now());
      debugPrint('✅ [AUTH] Time until re-auth needed: ${timeUntilExpiry.inDays} days');
      
      return expiry;
      
    } catch (e) {
      debugPrint('❌ [AUTH] Failed to get refresh token expiry using Bluesky library: $e');
      
      // フォールバック: エラーの場合は90日後
      debugPrint('⚠️ [AUTH] Using 90-day default as fallback');
      final defaultExpiry = DateTime.now().add(const Duration(days: 90));
      debugPrint('✅ [AUTH] Default refresh expiry set to: $defaultExpiry');
      
      return defaultExpiry;
    }
  }

  /// セッション更新後にプロフィール情報を更新
  /// 
  /// [accountDid] - プロフィールを更新するアカウントのDID
  Future<void> _updateProfileAfterRefresh(String accountDid) async {
    try {
      debugPrint('🔄 [AUTH] Starting profile update after session refresh for: ${accountDid.substring(0, 20)}...');
      
      // アカウント情報を取得
      final account = await database.accountDao.getAccountByDid(accountDid);
      if (account == null) {
        debugPrint('❌ [AUTH] Account not found for profile update: $accountDid');
        return;
      }

      if (account.accessJwt == null) {
        debugPrint('❌ [AUTH] No access token available for profile update');
        return;
      }

      // AT Protocolセッションを作成
      final session = atcore.Session(
        did: account.did,
        handle: account.handle,
        accessJwt: account.accessJwt!,
        refreshJwt: account.refreshJwt ?? '',
      );

      // Blueskyクライアントを作成（より高レベルのAPI）
      final blueskyClient = bsky.Bluesky.fromSession(session);
      
      // プロフィール情報を取得
      final profileResponse = await blueskyClient.actor.getProfile(actor: accountDid);
      final profileData = profileResponse.data;
      
      debugPrint('✅ [AUTH] Profile fetched successfully:');
      debugPrint('   Handle: ${profileData.handle}');
      debugPrint('   DisplayName: ${profileData.displayName ?? 'null'}');
      debugPrint('   Avatar: ${profileData.avatar != null ? '${profileData.avatar!.substring(0, 50)}...' : 'null'}');
      
      // データベースに保存
      await database.accountDao.updateAccountProfile(
        did: accountDid,
        displayName: profileData.displayName,
        description: profileData.description,
        avatar: profileData.avatar,
        banner: profileData.banner,
      );
      
      debugPrint('✅ [AUTH] Profile updated successfully in database after session refresh');
    } catch (e) {
      debugPrint('❌ [AUTH] Failed to update profile after session refresh: $e');
      // プロフィール更新の失敗は致命的ではないため、エラーをログに記録するのみ
    }
  }
}