// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;

// Project imports:
import 'package:moodesky/core/providers/deck_provider.dart';
import 'package:moodesky/core/theme/app_themes.dart';
import 'package:moodesky/features/home/widgets/deck_layout/deck_utils.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/shared/widgets/common/theme_helpers.dart';
import 'package:moodesky/shared/widgets/bluesky_facet_text.dart';

/// デッキアイテムの基本レイアウト - PostItemと統一されたデザイン
class DeckItem extends ConsumerWidget {
  final Widget avatar;
  final String title;
  final String subtitle;
  final String? timestamp;
  final String content;
  final List<bsky.Facet>? facets;
  final Function(String)? onMentionTap;
  final Function(String)? onLinkTap;
  final Function(String)? onHashtagTap;
  final List<Widget>? actionButtons;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accentColor;
  final Deck? deck; // デッキメニュー表示用（削除処理はDeckUtilsで統一）
  final Widget? embedWidget;

  const DeckItem({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.content,
    this.facets,
    this.onMentionTap,
    this.onLinkTap,
    this.onHashtagTap,
    this.actionButtons,
    this.onTap,
    this.trailing,
    this.accentColor,
    this.deck,
    this.embedWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.appTextStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.isLight ? Colors.white : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1.0,
              ),
              boxShadow: context.isLight ? AppThemes.premiumShadow : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // ユーザー情報行（PostItemと同じレイアウト）
          Row(
            children: [
              // アバター
              avatar,

              const SizedBox(width: 12),

              // タイトルとサブタイトル
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: textStyles.bodySmall.copyWith(
                        color: context.isLight
                            ? const Color(0xFF424242)
                            : const Color(0xFFCCCCCC),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // タイムスタンプまたはトレイリング
              if (timestamp != null)
                Text(
                  timestamp!,
                  style: textStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              if (trailing != null) trailing!,
            ],
          ),

          const SizedBox(height: 12),

          // コンテンツ（facets対応）
          Builder(
            builder: (context) {
              if (facets != null && facets!.isNotEmpty) {
                debugPrint('📝 DeckItem using BlueskyFacetText for ${facets!.length} facets');
                return BlueskyFacetText(
                  text: content,
                  facets: facets!,
                  style: textStyles.bodyLarge.copyWith(
                    // facetsのデフォルト色を設定（facetテキスト以外の部分用）
                    color: context.isLight
                        ? const Color(0xFF000000) // 純粋な黒
                        : const Color(0xFFF5F5F5),
                    fontWeight: FontWeight.w400, // Regular
                  ),
                  onMentionTap: onMentionTap,
                  onLinkTap: onLinkTap,
                  onHashtagTap: onHashtagTap,
                );
              } else {
                debugPrint('📝 DeckItem using regular Text (no facets)');
                return Text(
                  content,
                  style: textStyles.bodyLarge.copyWith(
                    color: context.isLight
                        ? const Color(0xFF000000) // 純粋な黒
                        : const Color(0xFFF5F5F5),
                    fontWeight: FontWeight.w400, // Regular
                  ),
                );
              }
            },
          ),

          // 埋め込みコンテンツ（アクションボタンの上に表示）
          if (embedWidget != null) ...[
            const SizedBox(height: 12),
            embedWidget!,
          ],

          // アクションボタンまたはメニューボタンがある場合のみスペースを追加
          if ((actionButtons != null && actionButtons!.isNotEmpty) ||
              deck != null) ...[
            const SizedBox(height: 16),

            // アクションボタン行（メニューボタンを常に含む）
            Row(
              children: [
                // アクションボタンがある場合は表示
                if (actionButtons != null && actionButtons!.isNotEmpty) ...[
                  ...actionButtons!
                      .expand((widget) => [widget, const SizedBox(width: 24)])
                      .take(actionButtons!.length * 2 - 1),
                ],

                const Spacer(),

                // デッキが指定されている場合はメニューボタンを表示
                if (deck != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      color: context.isLight
                          ? const Color(0xFF424242)
                          : const Color(0xFFCCCCCC),
                    ),
                    onSelected: (value) async {
                      debugPrint(
                        '🔽 DeckItem menu selected: $value for deck: ${deck!.title}',
                      );

                      // 現在のデッキリストから正確なインデックスを取得
                      final decksAsync = ref.read(decksStreamProvider);
                      final decks = decksAsync.valueOrNull ?? [];
                      final currentIndex = decks.indexWhere(
                        (d) => d.deckId == deck!.deckId,
                      );

                      debugPrint(
                        '🔽 Current deck index: $currentIndex, total decks: ${decks.length}',
                      );

                      // DeckUtilsで統一された処理を使用
                      await DeckUtils.handleDeckMenuAction(
                        context,
                        ref,
                        value,
                        deck!,
                        currentIndex >= 0 ? currentIndex : 0,
                        decks.length,
                      );
                      debugPrint('🔽 DeckItem menu action completed: $value');
                    },
                    itemBuilder: (context) {
                      // メニュー構築時も正確なインデックスを使用
                      final decksAsync = ref.read(decksStreamProvider);
                      final decks = decksAsync.valueOrNull ?? [];
                      final currentIndex = decks.indexWhere(
                        (d) => d.deckId == deck!.deckId,
                      );

                      return DeckUtils.buildDeckMenuItems(
                        context,
                        currentIndex >= 0 ? currentIndex : 0,
                        decks.length,
                      );
                    },
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
  }
}

/// 通知アイテム
class NotificationItem extends StatelessWidget {
  final String type; // 'like', 'repost', 'follow', 'mention', 'reply'
  final String actorName;
  final String actorHandle;
  final String? actorAvatar;
  final String? postContent;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final Deck? deck;

  const NotificationItem({
    super.key,
    required this.type,
    required this.actorName,
    required this.actorHandle,
    this.actorAvatar,
    this.postContent,
    required this.timestamp,
    this.onTap,
    this.deck,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = _getNotificationInfo(context);

    return DeckItem(
      avatar: CircleAvatar(
        radius: 20,
        backgroundImage: actorAvatar != null
            ? NetworkImage(actorAvatar!)
            : null,
        child: actorAvatar == null
            ? Text(
                actorName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: actorName,
      subtitle: '@$actorHandle',
      timestamp: _formatTimestamp(timestamp),
      content: text,
      trailing: Icon(icon, color: color, size: 16),
      onTap: onTap,
      accentColor: color,
      deck: deck,
    );
  }

  (IconData, Color, String) _getNotificationInfo(BuildContext context) {
    switch (type) {
      case 'like':
        return (
          Icons.favorite_rounded,
          Theme.of(context).colorScheme.likeColor,
          '${AppLocalizations.of(context).notificationLike}${postContent != null ? '\n"$postContent"' : ''}',
        );
      case 'repost':
        return (
          Icons.repeat_rounded,
          Theme.of(context).colorScheme.repostColor,
          '${AppLocalizations.of(context).notificationRepost}${postContent != null ? '\n"$postContent"' : ''}',
        );
      case 'follow':
        return (
          Icons.person_add_rounded,
          Theme.of(context).colorScheme.secondary,
          AppLocalizations.of(context).notificationFollow,
        );
      case 'mention':
        return (
          Icons.alternate_email_rounded,
          Theme.of(context).colorScheme.tertiary,
          '${AppLocalizations.of(context).notificationMention}${postContent != null ? '\n"$postContent"' : ''}',
        );
      case 'reply':
        return (
          Icons.chat_bubble_rounded,
          Theme.of(context).colorScheme.primary,
          '${AppLocalizations.of(context).notificationReply}${postContent != null ? '\n"$postContent"' : ''}',
        );
      default:
        return (
          Icons.notifications_rounded,
          Theme.of(context).colorScheme.onSurfaceVariant,
          AppLocalizations.of(context).notification,
        );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}

/// プロフィールポストアイテム
class ProfilePostItem extends StatelessWidget {
  final String authorName;
  final String authorHandle;
  final String? authorAvatar;
  final String content;
  final List<bsky.Facet> facets;
  final DateTime timestamp;
  final int likeCount;
  final int repostCount;
  final int replyCount;
  final bool isLiked;
  final bool isReposted;
  final VoidCallback? onLike;
  final VoidCallback? onRepost;
  final VoidCallback? onReply;
  final VoidCallback? onTap;
  final Function(String)? onMentionTap;
  final Function(String)? onLinkTap;
  final Function(String)? onHashtagTap;
  final Deck? deck;
  final Widget? embedWidget;

  const ProfilePostItem({
    super.key,
    required this.authorName,
    required this.authorHandle,
    this.authorAvatar,
    required this.content,
    this.facets = const [],
    required this.timestamp,
    this.likeCount = 0,
    this.repostCount = 0,
    this.replyCount = 0,
    this.isLiked = false,
    this.isReposted = false,
    this.onLike,
    this.onRepost,
    this.onReply,
    this.onTap,
    this.onMentionTap,
    this.onLinkTap,
    this.onHashtagTap,
    this.deck,
    this.embedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return DeckItem(
      avatar: CircleAvatar(
        radius: 20,
        backgroundImage: authorAvatar != null
            ? NetworkImage(authorAvatar!)
            : null,
        child: authorAvatar == null
            ? Text(
                authorName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: authorName,
      subtitle: '@$authorHandle',
      timestamp: _formatTimestamp(timestamp),
      content: content,
      facets: facets,
      onMentionTap: onMentionTap,
      onLinkTap: onLinkTap,
      onHashtagTap: onHashtagTap,
      embedWidget: embedWidget,
      actionButtons: [
        _buildActionButton(
          context: context,
          icon: Icons.chat_bubble_outline_rounded,
          count: replyCount,
          onTap: onReply,
        ),
        _buildActionButton(
          context: context,
          icon: Icons.repeat_rounded,
          count: repostCount,
          isActive: isReposted,
          activeColor: Theme.of(context).colorScheme.repostColor,
          onTap: onRepost,
        ),
        _buildActionButton(
          context: context,
          icon: isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          count: likeCount,
          isActive: isLiked,
          activeColor: Theme.of(context).colorScheme.likeColor,
          onTap: onLike,
        ),
      ],
      onTap: onTap,
      deck: deck,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required int count,
    bool isActive = false,
    Color? activeColor,
    VoidCallback? onTap,
  }) {
    final color = isActive && activeColor != null
        ? activeColor
        : (Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF424242)
              : const Color(0xFFCCCCCC));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatCount(count),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      if (k == k.round()) {
        return '${k.round()}K';
      } else {
        return '${k.toStringAsFixed(1)}K';
      }
    } else {
      final m = count / 1000000;
      if (m == m.round()) {
        return '${m.round()}M';
      } else {
        return '${m.toStringAsFixed(1)}M';
      }
    }
  }
}

/// 検索結果アイテム
class SearchResultItem extends StatelessWidget {
  final String type; // 'user', 'post', 'hashtag'
  final String title;
  final String subtitle;
  final String? avatar;
  final String content;
  final String? metadata;
  final VoidCallback? onTap;
  final Deck? deck;

  const SearchResultItem({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    this.avatar,
    required this.content,
    this.metadata,
    this.onTap,
    this.deck,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getSearchTypeInfo(context);

    return DeckItem(
      avatar: avatar != null
          ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatar!))
          : CircleAvatar(radius: 20, child: Icon(icon, color: color)),
      title: title,
      subtitle: subtitle,
      timestamp: metadata,
      content: content,
      onTap: onTap,
      accentColor: color,
      deck: deck,
    );
  }

  (IconData, Color) _getSearchTypeInfo(BuildContext context) {
    switch (type) {
      case 'user':
        return (Icons.person, Theme.of(context).colorScheme.primary);
      case 'post':
        return (Icons.article, Theme.of(context).colorScheme.secondary);
      case 'hashtag':
        return (Icons.tag, Theme.of(context).colorScheme.tertiary);
      default:
        return (Icons.search, Theme.of(context).colorScheme.onSurfaceVariant);
    }
  }
}

/// リストアイテム
class ListMemberItem extends StatelessWidget {
  final String name;
  final String handle;
  final String? avatar;
  final String? bio;
  final bool isFollowing;
  final VoidCallback? onFollow;
  final VoidCallback? onTap;
  final Deck? deck;

  const ListMemberItem({
    super.key,
    required this.name,
    required this.handle,
    this.avatar,
    this.bio,
    this.isFollowing = false,
    this.onFollow,
    this.onTap,
    this.deck,
  });

  @override
  Widget build(BuildContext context) {
    return DeckItem(
      avatar: CircleAvatar(
        radius: 20,
        backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
        child: avatar == null
            ? Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: name,
      subtitle: '@$handle',
      content: bio ?? AppLocalizations.of(context).noProfileInfo,
      trailing: OutlinedButton(
        onPressed: onFollow,
        child: Text(
          isFollowing
              ? AppLocalizations.of(context).following
              : AppLocalizations.of(context).follow,
        ),
      ),
      onTap: onTap,
      deck: deck,
    );
  }
}
