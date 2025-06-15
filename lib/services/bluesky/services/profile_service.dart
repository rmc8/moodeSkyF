// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:bluesky/bluesky.dart' as bsky;

// Project imports:
import 'package:moodesky/services/database/database.dart';

/// プロフィール情報を格納するモデル
class ProfileInfo {
  final String did;
  final String handle;
  final String? displayName;
  final String? description;
  final String? avatar;
  final String? banner;

  const ProfileInfo({
    required this.did,
    required this.handle,
    this.displayName,
    this.description,
    this.avatar,
    this.banner,
  });

  @override
  String toString() {
    return 'ProfileInfo(did: $did, handle: $handle, displayName: $displayName, avatar: $avatar)';
  }
}

/// Bluesky プロフィール取得・管理サービス
/// 
/// アカウントのプロフィール情報（アバター、表示名等）の取得と
/// データベースへの保存を管理する
class ProfileService {
  final AppDatabase database;

  ProfileService({
    required this.database,
  });

  /// 指定されたDIDのプロフィール情報を取得
  /// 
  /// [client] - 認証済みのBlueskyクライアント
  /// [did] - 取得するアカウントのDID
  /// 
  /// Returns: ProfileInfo または null（取得失敗時）
  Future<ProfileInfo?> getProfile({
    required bsky.Bluesky client,
    required String did,
  }) async {
    try {
      debugPrint('🔍 [PROFILE] Fetching profile for DID: ${did.substring(0, 20)}...');
      
      final response = await client.actor.getProfile(actor: did);
      final profile = response.data;
      
      debugPrint('✅ [PROFILE] Profile fetched successfully:');
      debugPrint('   Handle: ${profile.handle}');
      debugPrint('   DisplayName: ${profile.displayName ?? 'null'}');
      debugPrint('   Avatar: ${profile.avatar != null ? '${profile.avatar!.substring(0, 50)}...' : 'null'}');
      debugPrint('   Banner: ${profile.banner != null ? '${profile.banner!.substring(0, 50)}...' : 'null'}');
      
      return ProfileInfo(
        did: profile.did,
        handle: profile.handle,
        displayName: profile.displayName,
        description: profile.description,
        avatar: profile.avatar,
        banner: profile.banner,
      );
    } catch (e) {
      debugPrint('❌ [PROFILE] Failed to fetch profile for $did: $e');
      return null;
    }
  }

  /// プロフィール情報をデータベースに保存
  /// 
  /// [profile] - 保存するプロフィール情報
  /// 
  /// Returns: 更新成功時true、失敗時false
  Future<bool> updateProfileInDatabase(ProfileInfo profile) async {
    try {
      debugPrint('💾 [PROFILE] Updating profile in database for ${profile.handle}');
      
      final rowsAffected = await database.accountDao.updateAccountProfile(
        did: profile.did,
        displayName: profile.displayName,
        description: profile.description,
        avatar: profile.avatar,
        banner: profile.banner,
      );
      
      if (rowsAffected > 0) {
        debugPrint('✅ [PROFILE] Profile updated successfully in database');
        return true;
      } else {
        debugPrint('⚠️ [PROFILE] No rows affected - account may not exist in database');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PROFILE] Failed to update profile in database: $e');
      return false;
    }
  }

  /// プロフィール取得とデータベース更新を一括実行
  /// 
  /// [client] - 認証済みのBlueskyクライアント
  /// [did] - 更新するアカウントのDID
  /// 
  /// Returns: 成功時true、失敗時false
  Future<bool> fetchAndUpdateProfile({
    required bsky.Bluesky client,
    required String did,
  }) async {
    debugPrint('🔄 [PROFILE] Starting fetch and update for DID: ${did.substring(0, 20)}...');
    
    final profile = await getProfile(client: client, did: did);
    if (profile == null) {
      debugPrint('❌ [PROFILE] Failed to fetch profile, skipping database update');
      return false;
    }

    final success = await updateProfileInDatabase(profile);
    if (success) {
      debugPrint('✅ [PROFILE] Complete: Profile fetched and updated successfully');
    } else {
      debugPrint('❌ [PROFILE] Failed to update profile in database');
    }
    
    return success;
  }

  /// 複数アカウントのプロフィールを一括更新
  /// 
  /// [accounts] - 更新するアカウントのリスト（DIDとクライアントのペア）
  /// 
  /// Returns: 成功したアカウント数
  Future<int> fetchAndUpdateMultipleProfiles(
    List<({String did, bsky.Bluesky client})> accounts,
  ) async {
    debugPrint('🔄 [PROFILE] Starting bulk profile update for ${accounts.length} accounts');
    
    int successCount = 0;
    
    for (final account in accounts) {
      try {
        final success = await fetchAndUpdateProfile(
          client: account.client,
          did: account.did,
        );
        
        if (success) {
          successCount++;
        }
        
        // API負荷軽減のため短い間隔を空ける
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('❌ [PROFILE] Error updating profile for ${account.did}: $e');
      }
    }
    
    debugPrint('✅ [PROFILE] Bulk update complete: $successCount/${accounts.length} accounts updated');
    return successCount;
  }
}