import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart' as bsky;

import 'embed_record_widget.dart';
import 'embed_images_widget.dart';
import 'embed_external_widget.dart';
import 'embed_video_widget.dart';

/// メディア付き投稿引用埋め込みウィジェット
/// 
/// AT Protocolのメディア付き投稿引用埋め込み（bsky.EmbedRecordWithMedia）を表示する。
/// 投稿引用とメディア（画像、動画、外部リンク）を組み合わせて表示し、
/// 投稿コンテンツとメディアの両方を適切にレイアウトする。
class EmbedRecordWithMediaWidget extends StatelessWidget {
  /// 表示するメディア付き投稿引用埋め込みデータ
  final bsky.EmbedRecordWithMedia recordWithMedia;

  /// カードの角の丸み
  final double borderRadius;

  /// ウィジェット間のスペース
  final double spacing;

  /// 投稿タップ時のコールバック
  final void Function(String uri)? onRecordTap;

  /// ユーザータップ時のコールバック
  final void Function(String did)? onUserTap;

  /// 画像タップ時のコールバック
  final void Function(bsky.EmbedImages images, int index)? onImageTap;

  /// リンクタップ時のコールバック
  final void Function(String uri)? onLinkTap;

  /// 最大高さ制限
  final double? maxHeight;

  const EmbedRecordWithMediaWidget({
    super.key,
    required this.recordWithMedia,
    this.borderRadius = 8.0,
    this.spacing = 8.0,
    this.onRecordTap,
    this.onUserTap,
    this.onImageTap,
    this.onLinkTap,
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
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 投稿引用部分
          EmbedRecordWidget(
            record: recordWithMedia.record,
            borderRadius: 0.0, // 外側コンテナで丸みを付けるため
            onRecordTap: onRecordTap,
            onUserTap: onUserTap,
          ),
          
          // 区切り線
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          
          // メディア部分
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildMediaContent(context),
          ),
        ],
      ),
    );
  }

  /// メディアコンテンツを構築
  Widget _buildMediaContent(BuildContext context) {
    return recordWithMedia.media.when(
      // 画像メディア
      images: (bsky.EmbedImages images) => EmbedImagesWidget(
        images: images,
        onImageTap: (image, index) => onImageTap?.call(images, index),
      ),
      
      // 動画メディア
      video: (bsky.EmbedVideo video) => EmbedVideoWidget(
        video: video,
      ),
      
      // 外部リンクメディア
      external: (bsky.EmbedExternal external) => EmbedExternalWidget(
        external: external,
        onLinkTap: onLinkTap,
      ),
      
      // 未知のメディアタイプ
      unknown: (Map<String, dynamic> unknown) => _buildUnknownMedia(context),
      orElse: () => _buildUnknownMedia(context),
    );
  }

  /// 未知のメディアタイプの場合のフォールバックウィジェット
  Widget _buildUnknownMedia(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'サポートされていないメディアタイプです',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// デバッグ用：メディアタイプを取得
  String getMediaType() {
    return recordWithMedia.media.when(
      images: (_) => 'images',
      video: (_) => 'video',
      external: (_) => 'external',
      unknown: (_) => 'unknown',
      orElse: () => 'unknown',
    );
  }

  /// デバッグ用：構成要素の情報を取得
  Map<String, dynamic> getComponentInfo() {
    return {
      'hasRecord': true,
      'mediaType': getMediaType(),
      'recordType': 'record', // EmbedRecordWidgetのgetRecordType()を使用することも可能
    };
  }

  /// カスタムレイアウト：メディアを上に、投稿引用を下に配置
  Widget buildInvertedLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // メディア部分（上）
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildMediaContent(context),
          ),
          
          // 区切り線
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          
          // 投稿引用部分（下）
          EmbedRecordWidget(
            record: recordWithMedia.record,
            borderRadius: 0.0, // 外側コンテナで丸みを付けるため
            onRecordTap: onRecordTap,
            onUserTap: onUserTap,
          ),
        ],
      ),
    );
  }

  /// コンパクトレイアウト：投稿引用とメディアを並列配置
  Widget buildCompactLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 投稿引用部分（左）
          Expanded(
            flex: 2,
            child: EmbedRecordWidget(
              record: recordWithMedia.record,
              borderRadius: 0.0,
              onRecordTap: onRecordTap,
              onUserTap: onUserTap,
            ),
          ),
          
          // 区切り線
          VerticalDivider(
            width: 1.0,
            thickness: 1.0,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          
          // メディア部分（右）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildMediaContent(context),
            ),
          ),
        ],
      ),
    );
  }
}