// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

import 'package:shimmer/shimmer.dart';

// Project imports:
import 'package:moodesky/core/theme/app_themes.dart';
import 'package:moodesky/shared/utils/url_utils.dart';

/// 現在のBluesky 0.18.10 EmbedView用のウィジェット
/// 
/// AT ProtocolのEmbedViewデータ（bsky.EmbedView）を受け取り、
/// 適切な表示ウィジェットに振り分けて表示する。
/// 
/// サポートするEmbedViewタイプ：
/// - 画像（images）
/// - 動画（video）
/// - 外部リンク（external）
/// - 投稿引用（record）
/// - メディア付き投稿引用（recordWithMedia）
class EmbedViewWidget extends StatelessWidget {
  /// 画像間の余白サイズ
  static const double _imageSpacing = 4.0;

  /// 表示するEmbedViewデータ
  final bsky.EmbedView embedView;

  /// ウィジェット間のパディング
  final EdgeInsetsGeometry? padding;

  /// ウィジェットの角の丸み
  final BorderRadius? borderRadius;

  /// 背景色
  final Color? backgroundColor;

  /// 最大高さ制限
  final double? maxHeight;

  const EmbedViewWidget({
    super.key,
    required this.embedView,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // デフォルト値の設定
    final effectivePadding = padding ?? EdgeInsets.zero; // 余白なしに変更
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8.0);
    final effectiveBackgroundColor = backgroundColor ?? Colors.transparent; // 透明背景に変更

    return Container(
      padding: effectivePadding,
      decoration: effectiveBackgroundColor != Colors.transparent 
        ? BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: theme.brightness == Brightness.light ? AppThemes.premiumShadow : null,
          )
        : null, // 透明な場合は装飾なし
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      child: _buildEmbedViewContent(context),
    );
  }

  /// EmbedViewタイプに応じた適切なウィジェットを構築
  Widget _buildEmbedViewContent(BuildContext context) {
    return embedView.when(
      // 画像埋め込み
      images: (images) => _buildImagesEmbed(context, images),
      
      // 動画埋め込み
      video: (video) => _buildVideoEmbed(context, video),
      
      // 外部リンク埋め込み
      external: (external) => _buildExternalEmbed(context, external),
      
      // 投稿引用埋め込み
      record: (record) => _buildRecordEmbed(context, record),
      
      // メディア付き投稿引用埋め込み
      recordWithMedia: (recordWithMedia) => _buildRecordWithMediaEmbed(context, recordWithMedia),
      
      // 未知の埋め込みタイプまたはエラー処理
      unknown: (data) => _buildUnknownEmbed(context, data),
    );
  }

  /// 画像埋め込みウィジェット
  Widget _buildImagesEmbed(BuildContext context, dynamic images) {
    debugPrint('🖼️ Building images embed: ${images.runtimeType}');
    debugPrint('🖼️ Images object structure: ${images.toString()}');
    
    try {
      // 画像リストを抽出
      final imagesList = images.images as List<dynamic>?;
      
      if (imagesList == null || imagesList.isEmpty) {
        debugPrint('❌ No images found in embed');
        return _buildImagesPlaceholder(context);
      }
      
      debugPrint('🖼️ Found ${imagesList.length} images');
      
      // 画像数に応じてレイアウトを選択
      switch (imagesList.length) {
        case 1:
          return _buildSingleImage(context, imagesList[0]);
        case 2:
          return _buildTwoImages(context, imagesList);
        case 3:
          return _buildThreeImages(context, imagesList);
        case 4:
        default:
          return _buildFourImages(context, imagesList.take(4).toList());
      }
    } catch (e) {
      debugPrint('❌ Error building images embed: $e');
      return _buildImagesPlaceholder(context);
    }
  }
  
  /// 1枚画像レイアウト
  Widget _buildSingleImage(BuildContext context, dynamic image) {
    return AspectRatio(
      aspectRatio: 16 / 9, // 全体を16:9に統一
      child: _buildImageWidget(
        context, 
        image,
        aspectRatio: 16 / 9,
        borderRadius: BorderRadius.circular(6.0),
      ),
    );
  }
  
  /// 2枚画像レイアウト（横並び）
  Widget _buildTwoImages(BuildContext context, List<dynamic> images) {
    return AspectRatio(
      aspectRatio: 16 / 9, // 全体を16:9に統一
      child: Row(
        children: [
          Expanded(
            child: _buildImageWidget(
              context,
              images[0],
              aspectRatio: 8 / 9, // 16:9を2分割したアスペクト比
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6.0),
                bottomLeft: Radius.circular(6.0),
              ),
            ),
          ),
          SizedBox(width: _imageSpacing),
          Expanded(
            child: _buildImageWidget(
              context,
              images[1],
              aspectRatio: 8 / 9,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 3枚画像レイアウト（参考実装ベース）
  Widget _buildThreeImages(BuildContext context, List<dynamic> images) {
    return AspectRatio(
      aspectRatio: 16 / 9, // 全体を16:9に統一
      child: Row(
        children: [
          _buildSingleColumn(context, images[0]), // 左列：1枚
          SizedBox(width: _imageSpacing),
          _buildDoubleColumn(context, images[1], images[2]), // 右列：2枚
        ],
      ),
    );
  }
  
  /// 左列：1枚画像（3枚レイアウト用）
  Widget _buildSingleColumn(BuildContext context, dynamic image) {
    return Expanded(
      child: _buildImageWidget(
        context,
        image,
        aspectRatio: 8 / 9, // 16:9の半分幅
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6.0),
          bottomLeft: Radius.circular(6.0),
        ),
      ),
    );
  }
  
  /// 右列：2枚画像（3枚レイアウト用）
  Widget _buildDoubleColumn(BuildContext context, dynamic image1, dynamic image2) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          final imageHeight = (totalHeight - _imageSpacing) / 2; // 余白を引いて2で割る
          
          return Column(
            children: [
              SizedBox(
                height: imageHeight,
                child: _buildImageWidget(
                  context,
                  image1,
                  aspectRatio: null, // ピクセル値で高さ指定するためnull
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6.0),
                  ),
                ),
              ),
              SizedBox(height: _imageSpacing), // 余白はそのまま
              SizedBox(
                height: imageHeight,
                child: _buildImageWidget(
                  context,
                  image2,
                  aspectRatio: null, // ピクセル値で高さ指定するためnull
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(6.0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// 4枚画像レイアウト（2x2グリッド）
  Widget _buildFourImages(BuildContext context, List<dynamic> images) {
    return AspectRatio(
      aspectRatio: 16 / 9, // 全体を16:9に統一
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImageWidget(
                    context,
                    images[0],
                    aspectRatio: 8 / 4.5, // 半分幅、半分高さ
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6.0),
                    ),
                  ),
                ),
                SizedBox(width: _imageSpacing),
                Expanded(
                  child: _buildImageWidget(
                    context,
                    images[1],
                    aspectRatio: 8 / 4.5,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _imageSpacing),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImageWidget(
                    context,
                    images[2],
                    aspectRatio: 8 / 4.5,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6.0),
                    ),
                  ),
                ),
                SizedBox(width: _imageSpacing),
                Expanded(
                  child: _buildImageWidget(
                    context,
                    images[3],
                    aspectRatio: 8 / 4.5,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(6.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 共通画像ウィジェット
  Widget _buildImageWidget(
    BuildContext context,
    dynamic imageData, {
    required double? aspectRatio, // nullableに変更
    required BorderRadius borderRadius,
  }) {
    try {
      // 画像URLを抽出
      final thumbnailUrl = imageData.thumbnail as String?;
      
      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
        return _buildImagePlaceholder(context, aspectRatio, borderRadius);
      }
      
      return GestureDetector(
        onTap: () {
          // TODO: フルサイズ画像表示
          final fullsizeUrl = imageData.fullsize as String?;
          debugPrint('🖼️ Image tapped: thumbnail=$thumbnailUrl, fullsize=$fullsizeUrl');
        },
        child: aspectRatio != null 
          ? AspectRatio(
              aspectRatio: aspectRatio,
              child: _buildImageContainer(context, thumbnailUrl, borderRadius),
            )
          : _buildImageContainer(context, thumbnailUrl, borderRadius),
      );
    } catch (e) {
      debugPrint('❌ Error building image widget: $e');
      return _buildImagePlaceholder(context, aspectRatio, borderRadius);
    }
  }
  
  /// 画像コンテナ（AspectRatio有無に関わらず共通）
  Widget _buildImageContainer(BuildContext context, String thumbnailUrl, BorderRadius borderRadius) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          thumbnailUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              highlightColor: Theme.of(context).colorScheme.surfaceContainer,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: borderRadius,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Image load error: $error');
            return _buildImageError(context, null, borderRadius);
          },
        ),
      ),
    );
  }
  
  /// 画像プレースホルダー
  Widget _buildImagePlaceholder(BuildContext context, double? aspectRatio, BorderRadius borderRadius) {
    final theme = Theme.of(context);
    final content = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
          size: 32.0,
        ),
      ),
    );
    
    return aspectRatio != null 
      ? AspectRatio(aspectRatio: aspectRatio, child: content)
      : content;
  }
  
  /// 画像エラー表示
  Widget _buildImageError(BuildContext context, double? aspectRatio, BorderRadius borderRadius) {
    final theme = Theme.of(context);
    final content = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: theme.colorScheme.onSurfaceVariant,
              size: 32.0,
            ),
            SizedBox(height: _imageSpacing),
            Text(
              '画像読み込み失敗',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    
    return aspectRatio != null 
      ? AspectRatio(aspectRatio: aspectRatio, child: content)
      : content;
  }
  
  /// 画像埋め込みプレースホルダー（画像なしの場合）
  Widget _buildImagesPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.image,
            color: Theme.of(context).colorScheme.primary,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              '画像が見つかりません',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 動画埋め込みウィジェット
  Widget _buildVideoEmbed(BuildContext context, dynamic video) {
    debugPrint('🎥 Building video embed: ${video.runtimeType}');
    debugPrint('🎥 Video object structure: ${video.toString()}');
    
    try {
      // EmbedVideoViewの構造を分析
      _debugVideoStructure(video);
      
      // EmbedVideoViewからデータを抽出
      String? playlistUrl;
      String? thumbnailUrl;
      String? altText;
      double? aspectRatioValue;
      
      if (video != null) {
        // playlist URLの抽出
        try {
          playlistUrl = video.playlist as String?;
          debugPrint('🎥 Playlist URL: $playlistUrl');
        } catch (e) {
          debugPrint('❌ Failed to extract playlist: $e');
        }
        
        // サムネイルURLの抽出
        try {
          thumbnailUrl = video.thumbnail as String?;
          debugPrint('🎥 Thumbnail URL: $thumbnailUrl');
        } catch (e) {
          debugPrint('❌ Failed to extract thumbnail: $e');
        }
        
        // Alt textの抽出
        try {
          altText = video.alt as String?;
          debugPrint('🎥 Alt text: $altText');
        } catch (e) {
          debugPrint('❌ Failed to extract alt text: $e');
        }
        
        // アスペクト比の抽出
        try {
          final aspectRatio = video.aspectRatio;
          if (aspectRatio != null) {
            final width = aspectRatio.width as num?;
            final height = aspectRatio.height as num?;
            if (width != null && height != null && height != 0) {
              aspectRatioValue = width / height;
              debugPrint('🎥 Aspect ratio: $aspectRatioValue ($width:$height)');
            }
          }
        } catch (e) {
          debugPrint('❌ Failed to extract aspect ratio: $e');
        }
      }
      
      // 動画プレイヤーの構築
      return _buildVideoPlayer(
        context, 
        playlistUrl: playlistUrl,
        thumbnailUrl: thumbnailUrl,
        altText: altText,
        aspectRatio: aspectRatioValue ?? 16/9, // デフォルト16:9
      );
      
    } catch (e) {
      debugPrint('❌ Error building video embed: $e');
      return _buildVideoFallback(context, video);
    }
  }
  
  /// 動画構造をデバッグ
  void _debugVideoStructure(dynamic video) {
    debugPrint('🔍 Starting video structure analysis...');
    debugPrint('🔍 Video type: ${video.runtimeType}');
    debugPrint('🔍 video: $video');
    
    if (video != null) {
      final videoString = video.toString();
      debugPrint('🔍   video contains "playlist" in structure: ${videoString.contains('playlist')}');
      debugPrint('🔍   video contains "thumbnail" in structure: ${videoString.contains('thumbnail')}');
      debugPrint('🔍   video contains "alt" in structure: ${videoString.contains('alt')}');
      debugPrint('🔍   video contains "aspectRatio" in structure: ${videoString.contains('aspectRatio')}');
      debugPrint('🔍   video contains "cid" in structure: ${videoString.contains('cid')}');
      
      // 文字列の最初の200文字をプレビュー
      final preview = videoString.length > 200 ? '${videoString.substring(0, 200)}...' : videoString;
      debugPrint('🔍   video preview: $preview');
    }
  }
  
  /// 動画プレイヤーを構築
  Widget _buildVideoPlayer(
    BuildContext context, {
    required String? playlistUrl,
    required String? thumbnailUrl,
    required String? altText,
    required double aspectRatio,
  }) {
    final borderRadius = BorderRadius.circular(6.0);
    
    if (playlistUrl == null || playlistUrl.isEmpty) {
      debugPrint('🎥 No playlist URL available, showing fallback');
      return _buildVideoFallback(context, null);
    }
    
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: VideoPlayerWidget(
            playlistUrl: playlistUrl,
            thumbnailUrl: thumbnailUrl,
            altText: altText,
          ),
        ),
      ),
    );
  }
  
  /// 動画フォールバック表示
  Widget _buildVideoFallback(BuildContext context, dynamic video) {
    final borderRadius = BorderRadius.circular(6.0);
    
    return AspectRatio(
      aspectRatio: 16/9,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 48.0,
              ),
              const SizedBox(height: 12.0),
              Text(
                '動画を読み込めません',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (video != null)
                Text(
                  '(${video.runtimeType})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 外部リンク埋め込みウィジェット
  Widget _buildExternalEmbed(BuildContext context, dynamic external) {
    debugPrint('🔗 Building external embed: ${external.runtimeType}');
    debugPrint('🔗 External object structure: ${external.toString()}');
    
    // 詳細な構造調査
    _debugExternalStructure(external);
    
    try {
      // 直接新しいAPIデータを使用してカスタム外部リンクカードを構築
      return _buildModernExternalLinkCard(context, external);
    } catch (e) {
      debugPrint('❌ Error building external embed: $e');
      // フォールバック表示
      return _buildExternalFallback(context, external);
    }
  }
  
  /// 現在のAPI用のモダンな外部リンクカードを構築
  Widget _buildModernExternalLinkCard(BuildContext context, dynamic external) {
    final theme = Theme.of(context);
    
    try {
      // 新しいAPIからデータを抽出
      final externalData = external.external;
      final uri = externalData?.uri as String?;
      final title = externalData?.title as String?;
      final description = externalData?.description as String?;
      final thumbnailUrl = externalData?.thumbnail as String?; // URL文字列
      
      debugPrint('🔗 Modern card - URI: $uri, Title: $title, Thumbnail: $thumbnailUrl');
      
      if (uri == null) {
        return _buildExternalFallback(context, external);
      }
      
      return GestureDetector(
        onTap: () async {
          debugPrint('🔗 External link tapped: $uri');
          try {
            final success = await UrlUtils.launchExternalUrl(uri);
            if (!success) {
              debugPrint('❌ Failed to launch URL: $uri');
            }
          } catch (e) {
            debugPrint('❌ Error launching URL: $e');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: theme.brightness == Brightness.light ? AppThemes.premiumShadow : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // サムネイル画像
              if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                _buildNetworkThumbnail(context, thumbnailUrl),
              
              // リンク情報
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // 説明文
                    if (description != null && description.isNotEmpty) ...[ 
                      const SizedBox(height: 6.0),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // URL
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(
                          Icons.link,
                          size: 16.0,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6.0),
                        Expanded(
                          child: Text(
                            _formatUri(uri),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building modern external card: $e');
      return _buildExternalFallback(context, external);
    }
  }
  
  /// ネットワーク画像サムネイルを構築
  Widget _buildNetworkThumbnail(BuildContext context, String thumbnailUrl) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Thumbnail load error: $error');
          return Container(
            height: 200,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48.0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'サムネイル読み込みエラー',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// URIを表示用にフォーマット
  String _formatUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      final host = parsedUri.host;
      final path = parsedUri.path;
      
      // ホスト名のみ、または短いパスの場合は表示
      if (path.isEmpty || path == '/') {
        return host;
      }
      
      // パスが長い場合は省略
      if (path.length > 30) {
        return '$host${path.substring(0, 27)}...';
      }
      
      return '$host$path';
    } catch (e) {
      // パースエラーの場合はそのまま返す
      return uri;
    }
  }
  
  /// 外部リンクのフォールバック表示
  Widget _buildExternalFallback(BuildContext context, dynamic external) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.link,
            color: Theme.of(context).colorScheme.primary,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              '外部リンク (${external.runtimeType})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 外部リンクオブジェクトの構造を詳細調査
  void _debugExternalStructure(dynamic external) {
    debugPrint('🔍 External embed detailed analysis:');
    debugPrint('  Runtime type: ${external.runtimeType}');
    
    // 一般的なプロパティの存在をチェック
    final commonProps = ['uri', 'title', 'description', 'thumb', 'external'];
    for (final prop in commonProps) {
      try {
        final objString = external.toString();
        if (objString.contains(prop)) {
          debugPrint('  Contains "$prop" in structure');
        }
      } catch (e) {
        // エラーは無視
      }
    }
  }

  /// 投稿引用埋め込みウィジェット
  Widget _buildRecordEmbed(BuildContext context, dynamic record) {
    debugPrint('💬 Building record embed: ${record.runtimeType}');
    debugPrint('💬 Record object structure: ${record.toString()}');
    
    try {
      // レコードデータを抽出
      final recordData = _extractRecordData(record);
      
      if (recordData == null) {
        return _buildRecordError(context, 'レコードデータが見つかりません', record: record);
      }
      
      return GestureDetector(
        onTap: () {
          debugPrint('💬 Record tapped');
          // TODO: 引用投稿の詳細表示
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecordHeader(context, recordData),
                const SizedBox(height: 8.0),
                _buildRecordContent(context, recordData),
                if (_hasRecordImages(recordData)) ...[
                  const SizedBox(height: 8.0),
                  _buildRecordImages(context, recordData),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building record embed: $e');
      return _buildRecordError(context, 'レコードの読み込みに失敗しました: $e', record: record);
    }
  }

  /// メディア付き投稿引用埋め込みウィジェット
  Widget _buildRecordWithMediaEmbed(BuildContext context, dynamic recordWithMedia) {
    debugPrint('🎬 Building record with media embed: ${recordWithMedia.runtimeType}');
    debugPrint('🎬 RecordWithMedia object structure: ${recordWithMedia.toString()}');
    
    try {
      // recordWithMediaの構造を分析
      _debugRecordWithMediaStructure(recordWithMedia);
      
      // recordとmediaを抽出
      dynamic record;
      dynamic media;
      
      if (recordWithMedia != null) {
        try {
          record = recordWithMedia.record;
          debugPrint('🎬 Record extracted: ${record?.runtimeType}');
        } catch (e) {
          debugPrint('❌ Failed to extract record: $e');
        }
        
        try {
          media = recordWithMedia.media;
          debugPrint('🎬 Media extracted: ${media?.runtimeType}');
        } catch (e) {
          debugPrint('❌ Failed to extract media: $e');
        }
      }
      
      // メディア付きレコード埋め込みを構築
      return _buildRecordWithMediaContent(
        context,
        record: record,
        media: media,
      );
      
    } catch (e) {
      debugPrint('❌ Error building record with media embed: $e');
      return _buildRecordWithMediaFallback(context, recordWithMedia);
    }
  }
  
  /// レコード付きメディアの構造をデバッグ
  void _debugRecordWithMediaStructure(dynamic recordWithMedia) {
    debugPrint('🔍 Starting record with media structure analysis...');
    debugPrint('🔍 RecordWithMedia type: ${recordWithMedia.runtimeType}');
    debugPrint('🔍 recordWithMedia: $recordWithMedia');
    
    if (recordWithMedia != null) {
      final objString = recordWithMedia.toString();
      debugPrint('🔍   recordWithMedia contains "record" in structure: ${objString.contains('record')}');
      debugPrint('🔍   recordWithMedia contains "media" in structure: ${objString.contains('media')}');
      debugPrint('🔍   recordWithMedia contains "images" in structure: ${objString.contains('images')}');
      debugPrint('🔍   recordWithMedia contains "video" in structure: ${objString.contains('video')}');
      debugPrint('🔍   recordWithMedia contains "external" in structure: ${objString.contains('external')}');
      
      // 文字列の最初の200文字をプレビュー
      final preview = objString.length > 200 ? '${objString.substring(0, 200)}...' : objString;
      debugPrint('🔍   recordWithMedia preview: $preview');
    }
  }
  
  /// レコード付きメディアコンテンツを構築
  Widget _buildRecordWithMediaContent(
    BuildContext context, {
    required dynamic record,
    required dynamic media,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // メディア部分を最初に表示
        if (media != null) ...[
          _buildMediaWidget(context, media),
          const SizedBox(height: 8.0),
        ],
        
        // レコード部分を下に表示
        if (record != null)
          _buildRecordEmbed(context, record),
      ],
    );
  }
  
  /// メディアウィジェットを構築（images, video, external をサポート）
  Widget _buildMediaWidget(BuildContext context, dynamic media) {
    debugPrint('🎬 Building media widget: ${media.runtimeType}');
    
    try {
      // メディアタイプを判定してそれぞれの埋め込みウィジェットを呼び出し
      if (media != null) {
        final mediaString = media.toString();
        debugPrint('🎬 Media string contains: images=${mediaString.contains('images')}, video=${mediaString.contains('video')}, external=${mediaString.contains('external')}');
        
        // media.when() またはタイプチェックを使用してメディアタイプを判定
        try {
          // EmbedViewMediaのwhenパターンマッチングを試行
          return media.when(
            images: (images) {
              debugPrint('🎬 Media is images type');
              return _buildImagesEmbed(context, images);
            },
            video: (video) {
              debugPrint('🎬 Media is video type');
              return _buildVideoEmbed(context, video);
            },
            external: (external) {
              debugPrint('🎬 Media is external type');
              return _buildExternalEmbed(context, external);
            },
            unknown: (data) {
              debugPrint('🎬 Media is unknown type: ${data.runtimeType}');
              return _buildUnknownEmbed(context, data);
            },
          );
        } catch (e) {
          debugPrint('❌ when() pattern matching failed: $e');
          
          // フォールバック: 文字列ベースの判定
          if (mediaString.contains('EmbedVideoView') || mediaString.contains('video')) {
            debugPrint('🎬 Fallback: detected video media');
            return _buildVideoEmbed(context, media);
          } else if (mediaString.contains('EmbedImagesView') || mediaString.contains('images')) {
            debugPrint('🎬 Fallback: detected images media');
            return _buildImagesEmbed(context, media);
          } else if (mediaString.contains('EmbedExternalView') || mediaString.contains('external')) {
            debugPrint('🎬 Fallback: detected external media');
            return _buildExternalEmbed(context, media);
          } else {
            debugPrint('🎬 Fallback: unknown media type');
            return _buildUnknownEmbed(context, media);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error building media widget: $e');
    }
    
    return _buildUnknownEmbed(context, media);
  }
  
  /// レコード付きメディアのフォールバック表示
  Widget _buildRecordWithMediaFallback(BuildContext context, dynamic recordWithMedia) {
    final borderRadius = BorderRadius.circular(6.0);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.perm_media,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'メディア付き投稿引用',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (recordWithMedia != null)
                  Text(
                    '(${recordWithMedia.runtimeType})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 未知の埋め込みタイプの場合のフォールバックウィジェット
  Widget _buildUnknownEmbed(BuildContext context, dynamic data) {
    debugPrint('❓ Building unknown embed: ${data.runtimeType}');
    
    final theme = Theme.of(context);
    
    return Container(
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
              '未対応の埋め込みタイプ (${data.runtimeType})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// レコードデータを抽出（AT Protocol仕様準拠）
  Map<String, dynamic>? _extractRecordData(dynamic record) {
    debugPrint('🔍 Starting AT Protocol compliant record analysis...');
    debugPrint('🔍 Record type: ${record.runtimeType}');
    
    try {
      // record は EmbedViewRecord
      debugPrint('🔍 Accessing record.record (EmbedViewRecordView)...');
      final recordView = record.record; // EmbedViewRecordView (union型)
      
      if (recordView == null) {
        debugPrint('❌ recordView is null');
        return null;
      }
      
      debugPrint('🔍 RecordView type: ${recordView.runtimeType}');
      _debugRecordStructure(recordView, 'recordView');
      
      // union型の場合分けを実行
      // AT Protocol仕様: viewRecord, viewNotFound, viewBlocked, viewDetached など
      
      // Case 1: viewRecord - 実際の投稿データ
      try {
        // bluesky.dartライブラリでは UEmbedViewRecordViewRecord として実装
        if (recordView.runtimeType.toString().contains('UEmbedViewRecordViewRecord')) {
          debugPrint('🔍 Found UEmbedViewRecordViewRecord - extracting data...');
          final actualRecord = recordView.data; // EmbedViewRecordViewRecord
          
          debugPrint('🔍 ActualRecord type: ${actualRecord.runtimeType}');
          _debugRecordStructure(actualRecord, 'actualRecord');
          
          // 投稿者情報（ActorBasic）
          final author = actualRecord.author;
          debugPrint('🔍 Author type: ${author.runtimeType}');
          _debugRecordStructure(author, 'author');
          
          final authorName = author.displayName ?? author.handle;
          final authorHandle = author.handle;
          final authorAvatar = author.avatar;
          
          debugPrint('🔍 Author info extracted:');
          debugPrint('  - Name: $authorName');
          debugPrint('  - Handle: $authorHandle');
          debugPrint('  - Avatar: $authorAvatar');
          
          // 投稿内容（PostRecord）
          final postValue = actualRecord.value;
          debugPrint('🔍 PostValue type: ${postValue.runtimeType}');
          _debugRecordStructure(postValue, 'postValue');
          
          final text = postValue.text ?? '';
          debugPrint('🔍 Text extracted: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}"');
          
          // 埋め込みコンテンツ
          final embeds = actualRecord.embeds;
          debugPrint('🔍 Embeds: ${embeds?.length ?? 0} items');
          
          debugPrint('✅ Successfully extracted record data');
          return {
            'authorName': authorName,
            'authorHandle': authorHandle,
            'authorAvatar': authorAvatar,
            'text': text,
            'embeds': embeds,
            'uri': actualRecord.uri.toString(),
            'cid': actualRecord.cid,
            'likeCount': actualRecord.likeCount,
            'repostCount': actualRecord.repostCount,
            'replyCount': actualRecord.replyCount,
          };
        }
      } catch (e) {
        debugPrint('🔍 UEmbedViewRecordViewRecord extraction failed: $e');
      }
      
      // Case 2: Dynamic approach - プロパティが直接アクセス可能な場合
      try {
        debugPrint('🔍 Attempting dynamic property access...');
        
        // recordView上で直接プロパティにアクセス
        final author = recordView.author;
        final value = recordView.value;
        final uri = recordView.uri;
        
        if (author != null && value != null) {
          debugPrint('🔍 Dynamic access successful');
          _debugRecordStructure(author, 'dynamic_author');
          _debugRecordStructure(value, 'dynamic_value');
          
          final authorName = author.displayName ?? author.handle ?? 'Unknown User';
          final authorHandle = author.handle ?? '';
          final authorAvatar = author.avatar;
          final text = value.text ?? '';
          
          debugPrint('✅ Successfully extracted via dynamic access');
          return {
            'authorName': authorName,
            'authorHandle': authorHandle, 
            'authorAvatar': authorAvatar,
            'text': text,
            'embeds': recordView.embeds,
            'uri': uri?.toString(),
          };
        }
      } catch (e) {
        debugPrint('🔍 Dynamic property access failed: $e');
      }
      
      // Case 3: viewNotFound, viewBlocked, viewDetached などの処理
      final recordViewString = recordView.toString();
      if (recordViewString.contains('viewNotFound') || recordViewString.contains('notFound')) {
        debugPrint('🔍 Record not found');
        return {
          'authorName': '投稿が見つかりません',
          'authorHandle': '',
          'authorAvatar': null,
          'text': 'この投稿は削除されたか、アクセスできません。',
          'embeds': null,
          'isNotFound': true,
        };
      }
      
      if (recordViewString.contains('viewBlocked') || recordViewString.contains('blocked')) {
        debugPrint('🔍 Record blocked');
        return {
          'authorName': 'ブロックされたユーザー',
          'authorHandle': '',
          'authorAvatar': null,
          'text': 'この投稿は表示できません。',
          'embeds': null,
          'isBlocked': true,
        };
      }
      
      if (recordViewString.contains('viewDetached') || recordViewString.contains('detached')) {
        debugPrint('🔍 Record detached');
        return {
          'authorName': '切り離された投稿',
          'authorHandle': '',
          'authorAvatar': null,
          'text': 'この投稿は切り離されています。',
          'embeds': null,
          'isDetached': true,
        };
      }
      
      debugPrint('❌ Unknown record view type');
      return null;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error extracting record data: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// レコード構造をデバッグ出力
  void _debugRecordStructure(dynamic obj, String path) {
    if (obj == null) {
      debugPrint('🔍 $path: null');
      return;
    }
    
    debugPrint('🔍 $path: ${obj.runtimeType}');
    
    // よく使われるプロパティを確認
    final commonProperties = [
      'author', 'value', 'text', 'embed', 'embeds',
      'handle', 'displayName', 'avatar', 'did',
      'record', 'uri', 'cid'
    ];
    
    for (final prop in commonProperties) {
      try {
        // リフレクションの代わりに toString() でプロパティの存在を推測
        final objString = obj.toString();
        if (objString.contains(prop)) {
          debugPrint('🔍   $path contains "$prop" in structure');
        }
      } catch (e) {
        // エラーは無視
      }
    }
    
    // オブジェクトの文字列表現を確認（最初の200文字のみ）
    try {
      final objString = obj.toString();
      final preview = objString.length > 200 ? '${objString.substring(0, 200)}...' : objString;
      debugPrint('🔍   $path preview: $preview');
    } catch (e) {
      debugPrint('🔍   $path preview failed: $e');
    }
  }
  
  /// レコードヘッダー（投稿者情報）を構築
  Widget _buildRecordHeader(BuildContext context, Map<String, dynamic> recordData) {
    final theme = Theme.of(context);
    final authorName = recordData['authorName'] as String;
    final authorHandle = recordData['authorHandle'] as String;
    final authorAvatar = recordData['authorAvatar'] as String?;
    
    // 特別な状態の確認
    final isNotFound = recordData['isNotFound'] as bool? ?? false;
    final isBlocked = recordData['isBlocked'] as bool? ?? false;
    final isDetached = recordData['isDetached'] as bool? ?? false;
    
    // 特別な状態の場合のアイコン選択
    IconData headerIcon = Icons.format_quote;
    Color iconColor = theme.colorScheme.onSurfaceVariant;
    
    if (isNotFound) {
      headerIcon = Icons.not_interested;
      iconColor = theme.colorScheme.error;
    } else if (isBlocked) {
      headerIcon = Icons.block;
      iconColor = theme.colorScheme.error;
    } else if (isDetached) {
      headerIcon = Icons.link_off;
      iconColor = theme.colorScheme.onSurfaceVariant;
    }
    
    return Row(
      children: [
        // アバター
        CircleAvatar(
          radius: 16.0,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          backgroundImage: (!isNotFound && !isBlocked && !isDetached && 
                           authorAvatar != null && authorAvatar.isNotEmpty)
              ? NetworkImage(authorAvatar)
              : null,
          onBackgroundImageError: (exception, stackTrace) {
            // アバター画像の読み込みエラー時のログ出力
            debugPrint('❌ Avatar image load error: $exception');
          },
          child: (!isNotFound && !isBlocked && !isDetached && 
                 authorAvatar != null && authorAvatar.isNotEmpty)
              ? null  // アバター画像がある場合は子要素を表示しない
              : (isNotFound || isBlocked || isDetached)
                  ? Icon(
                      isNotFound ? Icons.person_off : 
                      isBlocked ? Icons.block :
                      Icons.person_outline,
                      size: 20.0,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
        ),
        
        const SizedBox(width: 8.0),
        
        // 名前とハンドル
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: (isNotFound || isBlocked) 
                      ? theme.colorScheme.onSurfaceVariant 
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (authorHandle.isNotEmpty && !isNotFound && !isBlocked)
                Text(
                  '@$authorHandle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        
        // 状態に応じたアイコン
        Icon(
          headerIcon,
          size: 16.0,
          color: iconColor,
        ),
      ],
    );
  }
  
  /// レコードコンテンツ（投稿テキスト）を構築
  Widget _buildRecordContent(BuildContext context, Map<String, dynamic> recordData) {
    final theme = Theme.of(context);
    final text = recordData['text'] as String;
    
    // 特別な状態の確認
    final isNotFound = recordData['isNotFound'] as bool? ?? false;
    final isBlocked = recordData['isBlocked'] as bool? ?? false;
    final isDetached = recordData['isDetached'] as bool? ?? false;
    
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: (isNotFound || isBlocked || isDetached)
            ? theme.colorScheme.onSurfaceVariant
            : null,
        fontStyle: (isNotFound || isBlocked || isDetached)
            ? FontStyle.italic
            : null,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// レコードに画像があるかチェック
  bool _hasRecordImages(Map<String, dynamic> recordData) {
    final embeds = recordData['embeds'];
    if (embeds == null) return false;
    
    try {
      // 埋め込み内容をチェック（簡易実装）
      final embedString = embeds.toString();
      return embedString.contains('images') || embedString.contains('image');
    } catch (e) {
      return false;
    }
  }
  
  /// レコード画像を構築
  Widget _buildRecordImages(BuildContext context, Map<String, dynamic> recordData) {
    final theme = Theme.of(context);
    
    // 簡易実装：画像プレースホルダー
    return Container(
      height: 100.0,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              '画像',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// レコードエラー表示を構築
  Widget _buildRecordError(BuildContext context, String message, {dynamic record}) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          // デバッグ用の詳細情報表示
          if (record != null) ...[
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'デバッグ情報:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Type: ${record.runtimeType}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Data: ${record.toString().length > 100 ? '${record.toString().substring(0, 100)}...' : record.toString()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// デバッグ用：埋め込みタイプを取得
  String getEmbedViewType() {
    return embedView.when(
      images: (_) => 'images',
      video: (_) => 'video',
      external: (_) => 'external',
      record: (_) => 'record',
      recordWithMedia: (_) => 'recordWithMedia',
      unknown: (_) => 'unknown',
    );
  }
}

/// 動画プレイヤーウィジェット
class VideoPlayerWidget extends StatefulWidget {
  final String playlistUrl;
  final String? thumbnailUrl;
  final String? altText;
  
  const VideoPlayerWidget({
    super.key,
    required this.playlistUrl,
    this.thumbnailUrl,
    this.altText,
  });
  
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
  
  void _disposeControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
  }
  
  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎥 Initializing video player for: ${widget.playlistUrl}');
      
      // VideoPlayerControllerを作成
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.playlistUrl),
      );
      
      // 初期化
      await _videoController!.initialize();
      
      if (!mounted) return;
      
      // ChewieControllerを作成
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false, // 自動再生しない
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        autoInitialize: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          bufferedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        placeholder: _buildThumbnailPlaceholder(),
        errorBuilder: (context, errorMessage) {
          debugPrint('❌ Video player error: $errorMessage');
          return _buildError(errorMessage);
        },
      );
      
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
      
      debugPrint('✅ Video player initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize video player: $e');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isInitialized = false;
        });
      }
    }
  }
  
  Widget _buildThumbnailPlaceholder() {
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Thumbnail load error: $error');
              return _buildDefaultThumbnail();
            },
          ),
          // 動画インジケーター（左上）
          Positioned(
            top: 8.0,
            left: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 12.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 中央の大きな再生ボタン
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(20.0),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40.0,
              ),
            ),
          ),
          // 右下の動画時間インジケーター（プレースホルダー）
          Positioned(
            bottom: 8.0,
            right: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 10.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '--:--',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    return _buildDefaultThumbnail();
  }
  
  Widget _buildDefaultThumbnail() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          // 背景グラデーション
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ],
              ),
            ),
          ),
          // 動画インジケーター（左上）
          Positioned(
            top: 8.0,
            left: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 12.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 中央のコンテンツ
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48.0,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  '動画を再生',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildError(String errorMessage) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48.0,
            ),
            const SizedBox(height: 12.0),
            Text(
              '動画の読み込みに失敗しました',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoading() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12.0),
            Text(
              '動画を読み込み中...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // エラー状態
    if (_hasError) {
      return _buildError(_errorMessage ?? 'Unknown error');
    }
    
    // ローディング状態
    if (!_isInitialized || _chewieController == null) {
      return _buildLoading();
    }
    
    // 動画プレイヤー
    return Semantics(
      label: widget.altText ?? '動画コンテンツ',
      child: Chewie(
        controller: _chewieController!,
      ),
    );
  }
}