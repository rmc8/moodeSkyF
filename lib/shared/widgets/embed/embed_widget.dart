import 'package:flutter/material.dart';
import 'package:bluesky/bluesky.dart' as bsky;

import 'embed_images_widget.dart';
import 'embed_external_widget.dart';
import 'embed_record_widget.dart';
import 'embed_record_with_media_widget.dart';
import 'embed_video_widget.dart';

/// 汎用埋め込みウィジェット
/// 
/// AT Protocolの埋め込みデータ（bsky.Embed）を受け取り、
/// 適切な専用ウィジェットに振り分けて表示する。
/// 
/// サポートする埋め込みタイプ：
/// - 画像（EmbedImages）
/// - 動画（EmbedVideo）
/// - 外部リンク（EmbedExternal）
/// - 投稿引用（EmbedRecord）
/// - メディア付き投稿引用（EmbedRecordWithMedia）
class EmbedWidget extends StatelessWidget {
  /// 表示する埋め込みデータ
  final bsky.Embed embed;

  /// ウィジェット間のパディング
  final EdgeInsetsGeometry? padding;

  /// ウィジェットの角の丸み
  final BorderRadius? borderRadius;

  /// 背景色
  final Color? backgroundColor;

  /// 最大高さ制限
  final double? maxHeight;

  const EmbedWidget({
    super.key,
    required this.embed,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // デフォルト値の設定
    final effectivePadding = padding ?? const EdgeInsets.all(8.0);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8.0);
    final effectiveBackgroundColor = backgroundColor ?? 
        theme.cardColor.withValues(alpha: 0.5);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      child: _buildEmbedContent(context),
    );
  }

  /// 埋め込みタイプに応じた適切なウィジェットを構築
  Widget _buildEmbedContent(BuildContext context) {
    return embed.when(
      // 画像埋め込み
      images: (bsky.EmbedImages images) => EmbedImagesWidget(
        images: images,
      ),
      
      // 動画埋め込み
      video: (bsky.EmbedVideo video) => EmbedVideoWidget(
        video: video,
      ),
      
      // 外部リンク埋め込み
      external: (bsky.EmbedExternal external) => EmbedExternalWidget(
        external: external,
      ),
      
      // 投稿引用埋め込み
      record: (bsky.EmbedRecord record) => EmbedRecordWidget(
        record: record,
      ),
      
      // メディア付き投稿引用埋め込み
      recordWithMedia: (bsky.EmbedRecordWithMedia recordWithMedia) => 
        EmbedRecordWithMediaWidget(
          recordWithMedia: recordWithMedia,
        ),
      
      // 未知の埋め込みタイプまたはエラー処理
      unknown: (Map<String, dynamic> unknown) => _buildUnknownEmbed(context),
      orElse: () => _buildUnknownEmbed(context),
    );
  }

  /// 未知の埋め込みタイプの場合のフォールバックウィジェット
  Widget _buildUnknownEmbed(BuildContext context) {
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
              'サポートされていない埋め込みタイプです',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// デバッグ用：埋め込みタイプを取得
  String getEmbedType() {
    return embed.when(
      images: (_) => 'images',
      video: (_) => 'video',
      external: (_) => 'external',
      record: (_) => 'record',
      recordWithMedia: (_) => 'recordWithMedia',
      unknown: (_) => 'unknown',
      orElse: () => 'unknown',
    );
  }
}