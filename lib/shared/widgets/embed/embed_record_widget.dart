import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart' as bsky;

/// 投稿引用埋め込みウィジェット
/// 
/// AT Protocolの投稿引用埋め込み（bsky.EmbedRecord）を表示する。
/// 引用された投稿の作成者、投稿時間、テキストコンテンツ、
/// メタデータを引用カード形式で表示する。
class EmbedRecordWidget extends StatelessWidget {
  /// 表示する投稿引用埋め込みデータ
  final bsky.EmbedRecord record;

  /// カードの角の丸み
  final double borderRadius;

  /// 投稿タップ時のコールバック
  final void Function(String uri)? onRecordTap;

  /// ユーザータップ時のコールバック
  final void Function(String did)? onUserTap;

  /// 最大高さ制限
  final double? maxHeight;

  const EmbedRecordWidget({
    super.key,
    required this.record,
    this.borderRadius = 8.0,
    this.onRecordTap,
    this.onUserTap,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
      ),
      child: _buildRecordContent(context),
    );
  }

  /// 引用投稿の内容を構築
  Widget _buildRecordContent(BuildContext context) {
    return record.record.when(
      // 通常の投稿記録
      viewRecord: (bsky.EmbedRecordViewRecord viewRecord) => 
        _buildViewRecord(context, viewRecord),
      
      // 見つからない投稿
      viewNotFound: (bsky.EmbedRecordViewNotFound notFound) => 
        _buildNotFoundRecord(context),
      
      // ブロックされた投稿
      viewBlocked: (bsky.EmbedRecordViewBlocked blocked) => 
        _buildBlockedRecord(context),
      
      // 投稿生成エラー
      generatorView: (bsky.FeedGeneratorView generatorView) => 
        _buildGeneratorView(context, generatorView),
      
      // リストビュー
      listView: (bsky.GraphListView listView) => 
        _buildListView(context, listView),
      
      // 未知のレコードタイプ
      unknown: (Map<String, dynamic> unknown) => _buildUnknownRecord(context),
      orElse: () => _buildUnknownRecord(context),
    );
  }

  /// 通常の投稿記録表示
  Widget _buildViewRecord(BuildContext context, bsky.EmbedRecordViewRecord viewRecord) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => onRecordTap?.call(viewRecord.uri),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作成者情報
            _buildAuthorInfo(context, viewRecord.author),
            
            const SizedBox(height: 8.0),
            
            // 投稿内容
            if (viewRecord.value.text.isNotEmpty)
              Text(
                viewRecord.value.text,
                style: theme.textTheme.bodyMedium,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            
            const SizedBox(height: 8.0),
            
            // 投稿時間
            Text(
              _formatDateTime(viewRecord.value.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 作成者情報ウィジェット
  Widget _buildAuthorInfo(BuildContext context, bsky.ActorProfileViewBasic author) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => onUserTap?.call(author.did),
      child: Row(
        children: [
          // アバター
          CircleAvatar(
            radius: 16.0,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 20.0,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          
          const SizedBox(width: 8.0),
          
          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 表示名
                Text(
                  author.displayName ?? author.handle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // ハンドル
                Text(
                  '@${author.handle}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 見つからない投稿の表示
  Widget _buildNotFoundRecord(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              '投稿が見つかりません',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ブロックされた投稿の表示
  Widget _buildBlockedRecord(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.block,
            color: theme.colorScheme.error,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'ブロックされた投稿です',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// フィードジェネレータービューの表示
  Widget _buildGeneratorView(BuildContext context, bsky.FeedGeneratorView generatorView) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rss_feed,
                color: theme.colorScheme.primary,
                size: 24.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  generatorView.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (generatorView.description != null && generatorView.description!.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(
              generatorView.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// リストビューの表示
  Widget _buildListView(BuildContext context, bsky.GraphListView listView) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list,
                color: theme.colorScheme.primary,
                size: 24.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  listView.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (listView.description != null && listView.description!.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(
              listView.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 未知のレコードタイプの表示
  Widget _buildUnknownRecord(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: theme.colorScheme.onSurfaceVariant,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'サポートされていないレコードタイプです',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日時をフォーマット
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  /// デバッグ用：レコード情報を取得
  String getRecordType() {
    return record.record.when(
      viewRecord: (_) => 'viewRecord',
      viewNotFound: (_) => 'viewNotFound',
      viewBlocked: (_) => 'viewBlocked',
      generatorView: (_) => 'generatorView',
      listView: (_) => 'listView',
      unknown: (_) => 'unknown',
      orElse: () => 'unknown',
    );
  }
}