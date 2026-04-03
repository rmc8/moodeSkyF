// Flutter imports:
import 'dart:async';
import 'package:flutter/material.dart';

// Package imports:
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/bluesky_service_provider.dart';
import 'package:moodesky/core/providers/database_provider.dart';
import 'package:moodesky/features/home/providers/timeline_provider.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/services/bluesky/bluesky_service_v2.dart';
import 'package:moodesky/shared/models/auth_models.dart';
import 'package:moodesky/shared/widgets/deck_item.dart';
import 'package:moodesky/shared/widgets/simple_repost_widget.dart';
import 'package:moodesky/shared/widgets/embed_view_widget.dart';
import 'package:moodesky/shared/widgets/post_item/shimmer_post_item.dart';
import 'timeline_widget.dart';

/// Bluesky-specific timeline widget
class BlueskyTimelineWidget extends BaseTimelineWidget {
  const BlueskyTimelineWidget({
    super.key,
    required super.deck,
    super.showScrollButtons = true,
  });

  @override
  ConsumerState<BlueskyTimelineWidget> createState() => _BlueskyTimelineWidgetState();
}

class _BlueskyTimelineWidgetState extends BaseTimelineWidgetState<BlueskyTimelineWidget> {
  // パフォーマンス最適化とデバウンス機能
  Timer? _debounceTimer;
  Timer? _fallbackTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _fallbackDelay = Duration(seconds: 2);
  DateTime? _lastScrollEventTime;
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    // 初期データの読み込みを開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timelineProvider(widget.deck).notifier).loadInitial();
    });
    // Set up infinite scroll callback using base class mechanism
    setCustomScrollCallback(_handleInfiniteScroll);
  }

  void _handleInfiniteScroll() {
    try {
      final now = DateTime.now();
      _lastScrollEventTime = now;
      
      // スクロール位置の安全チェック
      if (!scrollController.hasClients || !mounted) {
        return;
      }
      
      final position = scrollController.position;
      final currentPixels = position.pixels;
      final maxExtent = position.maxScrollExtent;
      final threshold = widget.infiniteScrollThreshold;
      
      final timelineState = ref.read(timelineProvider(widget.deck));
      final distanceFromBottom = maxExtent - currentPixels;
      final shouldTrigger = distanceFromBottom <= threshold;
      final isLoadingOrError = timelineState.isLoadingMore || timelineState.isLoading || timelineState.error != null;
      final hasNextCursor = timelineState.cursor != null && timelineState.cursor!.trim().isNotEmpty;
      
      // Check if we're near the bottom and should load more
      if (shouldTrigger && hasNextCursor && !isLoadingOrError) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounceDelay, () {
          if (mounted) {
            ref.read(timelineProvider(widget.deck).notifier).loadMore();
          }
        });
      }
      
      // フォールバック機能
      final isAtBottomNow = distanceFromBottom <= 50;
      if (isAtBottomNow && !_isAtBottom && hasNextCursor && !isLoadingOrError) {
        _isAtBottom = true;
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(_fallbackDelay, () {
          if (mounted && _isAtBottom) {
            ref.read(timelineProvider(widget.deck).notifier).loadMore();
          }
        });
      } else if (!isAtBottomNow && _isAtBottom) {
        _isAtBottom = false;
        _fallbackTimer?.cancel();
      }
      
    } catch (e) {
      debugPrint('⚠️ Error in infinite scroll handler: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    if (!mounted) return;
    await ref.read(timelineProvider(widget.deck).notifier).refresh();
  }

  @override
  Widget buildContent() {
    final timelineState = ref.watch(timelineProvider(widget.deck));

    if (timelineState.error != null && timelineState.posts.isEmpty) {
      return _buildErrorState(timelineState.error!);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // オーバースクロール検出による pull-to-refresh
        if (notification is OverscrollNotification) {
          if (notification.overscroll < -30 && !timelineState.isRefreshing) {
            debugPrint('📱 Pull-to-refresh triggered by overscroll: ${notification.overscroll}');
            refresh();
          }
        }
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Loading indicator at top (for refresh)
          if (timelineState.isRefreshing)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).loadingNewPosts,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Loading indicator at top (for initial load)
          if (timelineState.isLoading && timelineState.posts.isEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const ShimmerPostItem(),
                childCount: 6,
              ),
            ),
          
          // Real timeline data
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= timelineState.posts.length) return null;
                
                final feedView = timelineState.posts[index];
                
                return _buildPostItem(feedView);
              },
              childCount: timelineState.posts.length,
            ),
          ),
          
          // Loading indicator at bottom
          if (timelineState.isLoadingMore)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).loadingOlderPosts,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostItem(bsky.FeedView feedView) {
    // Extract author information
    final author = feedView.post.author;
    final authorName = author.displayName ?? author.handle;
    final authorHandle = author.handle;
    final authorAvatar = author.avatar;
    
    // Extract post content and metadata
    final content = feedView.post.record.text;
    final facets = feedView.post.record.facets ?? [];
    final timestamp = feedView.post.indexedAt;
    final embedView = feedView.post.embed;
    
    // Extract engagement metrics (if available)
    final likeCount = feedView.post.likeCount;
    final repostCount = feedView.post.repostCount;
    final replyCount = feedView.post.replyCount;
    
    // Check if this is a repost and extract repost information
    Widget? repostWidget;
    if (feedView.reason != null) {
      feedView.reason!.when(
        repost: (repost) {
          repostWidget = SimpleRepostWidget(repost: repost);
        },
        pin: (pin) {},
        unknown: (data) {},
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Repost information (if available)
          if (repostWidget != null) repostWidget!,
          
          // Main post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            child: Column(
              children: [
                ProfilePostItem(
                  authorName: authorName,
                  authorHandle: authorHandle,
                  authorAvatar: authorAvatar,
                  content: content,
                  facets: facets,
                  timestamp: timestamp,
                  likeCount: likeCount,
                  repostCount: repostCount,
                  replyCount: replyCount,
                  isLiked: false, // TODO: Implement like state
                  isReposted: false, // TODO: Implement repost state
                  // Embed content (アクションボタンの上に表示)
                  embedWidget: embedView != null 
                    ? EmbedViewWidget(
                        embedView: embedView,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                  onLike: () {},
                  onRepost: () {},
                  onReply: () {},
                  onTap: () {},
                  onMentionTap: (did) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).richTextMentionTapped(did)),
                      ),
                    );
                  },
                  onLinkTap: (url) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).richTextUrlTapped(url)),
                      ),
                    );
                  },
                  onHashtagTap: (tag) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).richTextHashtagTapped(tag)),
                      ),
                    );
                  },
                  deck: widget.deck,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading timeline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}