// Flutter imports:
import 'dart:async';
import 'package:flutter/material.dart';

// Package imports:
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/providers/database_provider.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/services/bluesky/bluesky_service_v2.dart';
import 'package:moodesky/shared/models/auth_models.dart';
import 'package:moodesky/shared/widgets/deck_item.dart';
import 'package:moodesky/shared/widgets/simple_repost_widget.dart';
import 'package:moodesky/shared/widgets/embed_view_widget.dart';
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
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<bsky.FeedView> _feedData = [];
  String? _nextCursor;
  
  // パフォーマンス最適化とデバウンス機能
  Timer? _debounceTimer;
  Timer? _fallbackTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _fallbackDelay = Duration(seconds: 2);
  DateTime? _lastScrollEventTime;
  DateTime? _lastApiCallTime;
  bool _isAtBottom = false;
  
  // パフォーマンス測定用
  final Map<String, DateTime> _performanceStartTimes = {};
  int _totalApiCalls = 0;
  int _totalScrollEvents = 0;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
    // Set up infinite scroll callback using base class mechanism
    setCustomScrollCallback(_handleInfiniteScroll);
  }

  void _handleInfiniteScroll() {
    try {
      final now = DateTime.now();
      _lastScrollEventTime = now;
      
      // スクロール位置の安全チェック
      if (!scrollController.hasClients || !mounted) {
        debugPrint('📱 Infinite scroll skipped: no clients or not mounted');
        return;
      }
      
      final position = scrollController.position;
      final currentPixels = position.pixels;
      final maxExtent = position.maxScrollExtent;
      final threshold = widget.infiniteScrollThreshold;
      
      // 発火条件の詳細チェック
      final distanceFromBottom = maxExtent - currentPixels;
      final shouldTrigger = distanceFromBottom <= threshold;
      final isLoadingOrError = _isLoadingMore || _isLoading || _hasError;
      final hasNextCursor = _nextCursor != null && _nextCursor!.trim().isNotEmpty;
      
      debugPrint('📱 Scroll check: position=$currentPixels, max=$maxExtent, distance=$distanceFromBottom');
      debugPrint('📱 Trigger conditions: shouldTrigger=$shouldTrigger, hasNext=$hasNextCursor, loading=$isLoadingOrError');
      
      // Check if we're near the bottom and should load more
      if (shouldTrigger && hasNextCursor && !isLoadingOrError) {
        debugPrint('📱 Infinite scroll condition met - starting debounce timer');
        
        // デバウンス機能：短時間での連続呼び出しを防ぐ
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounceDelay, () {
          // 再度条件をチェック（デバウンス期間中に状態が変わった可能性）
          if (mounted && !_isLoadingMore && !_isLoading && _nextCursor != null) {
            debugPrint('📱 Infinite scroll triggered (debounced) - loading more posts');
            _logPerformanceMetrics('infinite_scroll_trigger', DateTime.now());
            _loadMore();
          } else {
            debugPrint('📱 Infinite scroll cancelled during debounce: mounted=$mounted, loading=${_isLoadingMore || _isLoading}, cursor=${_nextCursor != null}');
          }
        });
      } else if (shouldTrigger) {
        debugPrint('📱 Infinite scroll blocked: hasNext=$hasNextCursor, loading=$isLoadingOrError');
      }
      
      // フォールバック機能：最下部に一定時間いる場合に強制発火
      final isAtBottomNow = distanceFromBottom <= 50; // 50px以内を最下部とみなす
      if (isAtBottomNow && !_isAtBottom && hasNextCursor && !isLoadingOrError) {
        _isAtBottom = true;
        debugPrint('📱 User reached bottom - starting fallback timer');
        
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(_fallbackDelay, () {
          if (mounted && _isAtBottom && !_isLoadingMore && !_isLoading && _nextCursor != null) {
            debugPrint('📱 Fallback infinite scroll triggered - user stayed at bottom');
            _loadMore();
          }
        });
      } else if (!isAtBottomNow && _isAtBottom) {
        _isAtBottom = false;
        _fallbackTimer?.cancel();
        debugPrint('📱 User moved away from bottom - cancelling fallback timer');
      }
      
    } catch (e) {
      debugPrint('⚠️ Error in infinite scroll handler: $e');
    }
  }

  /// パフォーマンス測定の開始
  void _startPerformanceTimer(String operation) {
    _performanceStartTimes[operation] = DateTime.now();
  }

  /// パフォーマンス測定の終了とログ出力
  void _logPerformanceMetrics(String operation, DateTime? customEndTime) {
    final endTime = customEndTime ?? DateTime.now();
    final startTime = _performanceStartTimes[operation];
    
    if (startTime != null) {
      final duration = endTime.difference(startTime);
      debugPrint('⚡ Performance [$operation]: ${duration.inMilliseconds}ms');
      
      // 統計情報も出力
      if (operation.contains('api_call')) {
        _totalApiCalls++;
        debugPrint('📊 Total API calls: $_totalApiCalls');
      } else if (operation.contains('scroll')) {
        _totalScrollEvents++;
        debugPrint('📊 Total scroll events: $_totalScrollEvents');
      }
      
      _performanceStartTimes.remove(operation);
    }
  }

  /// メモリ使用量最適化：古いアイテムを削除
  void _optimizeMemoryUsage() {
    const maxItems = 100; // 最大保持アイテム数
    if (_feedData.length > maxItems) {
      final removeCount = _feedData.length - maxItems;
      _feedData.removeRange(0, removeCount);
      debugPrint('🧹 Memory optimization: Removed $removeCount old items, current count: ${_feedData.length}');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    if (_isLoading) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _startPerformanceTimer('initial_timeline_load_api_call');

    try {
      // Use the deck's account if specified, otherwise fall back to active account
      final String? accountDid;
      if (widget.deck.accountDid != null && !widget.deck.isCrossAccount) {
        // Use the specific account for this deck
        accountDid = widget.deck.accountDid;
        debugPrint('📱 Loading timeline for deck account: $accountDid');
      } else {
        // Cross-account deck or no specific account - use active account
        final activeAccount = ref.read(activeAccountProvider);
        if (activeAccount == null) {
          throw Exception('No active account');
        }
        accountDid = activeAccount.did;
        debugPrint('📱 Loading timeline for active account: $accountDid');
      }

      final database = ref.read(databaseProvider);
      final blueskyService = BlueskyServiceV2(
        database: database,
        secureStorage: const FlutterSecureStorage(),
        authConfig: const AuthConfig(defaultPdsHost: 'bsky.social'),
      );

      await blueskyService.initialize();

      final response = await blueskyService.getTimelineFeed(
        accountDid: accountDid!,
        limit: 50,
      );

      if (!mounted) return;
      setState(() {
        // API応答をmutableリストに変換して安全な操作を保証
        _feedData = response.feed.toList();
        _nextCursor = response.cursor;
        _isLoading = false;
        debugPrint('📱 Initial timeline loaded: ${_feedData.length} posts (converted to mutable list)');
      });
      
      _logPerformanceMetrics('initial_timeline_load_api_call', null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      // エラー時もパフォーマンス測定を終了
      _logPerformanceMetrics('initial_timeline_load_api_call', null);
    }
  }

  Future<void> _loadMore() async {
    // Prevent multiple simultaneous loads and check if we have a cursor
    if (_isLoadingMore || _nextCursor == null || _isLoading) {
      debugPrint('📱 Load more skipped: isLoadingMore=$_isLoadingMore, hasNextCursor=${_nextCursor != null}, isLoading=$_isLoading');
      return;
    }
    
    // Additional check for empty cursor
    if (_nextCursor?.trim().isEmpty == true) {
      debugPrint('📱 Load more skipped: cursor is empty');
      return;
    }

    debugPrint('📱 Starting to load more posts with cursor: $_nextCursor');
    setState(() {
      _isLoadingMore = true;
    });

    _startPerformanceTimer('load_more_api_call');

    try {
      // Use the same account logic as _loadTimeline
      final String? accountDid;
      if (widget.deck.accountDid != null && !widget.deck.isCrossAccount) {
        // Use the specific account for this deck
        accountDid = widget.deck.accountDid;
        debugPrint('📱 Loading more posts for deck account: $accountDid');
      } else {
        // Cross-account deck or no specific account - use active account
        final activeAccount = ref.read(activeAccountProvider);
        if (activeAccount == null) {
          throw Exception('No active account');
        }
        accountDid = activeAccount.did;
        debugPrint('📱 Loading more posts for active account: $accountDid');
      }

      final database = ref.read(databaseProvider);
      final blueskyService = BlueskyServiceV2(
        database: database,
        secureStorage: const FlutterSecureStorage(),
        authConfig: const AuthConfig(defaultPdsHost: 'bsky.social'),
      );

      await blueskyService.initialize();

      final response = await blueskyService.getTimelineFeed(
        accountDid: accountDid!,
        cursor: _nextCursor,
        limit: 50,
      );

      if (!mounted) return;
      setState(() {
        final previousCount = _feedData.length;
        
        // Check for duplicates and log details
        final newPosts = <bsky.FeedView>[];
        // API応答をmutableリストに変換してから処理
        final apiPosts = response.feed.toList();
        for (final post in apiPosts) {
          final isDuplicate = _feedData.any((existing) => 
            existing.post.cid == post.post.cid);
          if (!isDuplicate) {
            newPosts.add(post);
          }
        }
        
        // 安全なaddAll操作
        try {
          _feedData.addAll(newPosts);
        } catch (e) {
          debugPrint('⚠️ Error adding posts to list: $e');
          // フォールバック：新しいリストを作成
          _feedData = [..._feedData, ...newPosts];
        }
        
        _nextCursor = response.cursor;
        _isLoadingMore = false;
        
        debugPrint('📱 Load more completed:');
        debugPrint('  - API returned: ${response.feed.length} posts');
        debugPrint('  - Duplicates filtered: ${response.feed.length - newPosts.length}');
        debugPrint('  - Actually added: ${newPosts.length} posts');
        debugPrint('  - Total posts: ${_feedData.length} (was: $previousCount)');
        debugPrint('  - Next cursor: ${_nextCursor ?? "null"}');
        
        if (newPosts.isNotEmpty) {
          debugPrint('  - Oldest new post: ${newPosts.last.post.indexedAt}');
        }
        
        // メモリ最適化を実行
        _optimizeMemoryUsage();
      });
      
      _logPerformanceMetrics('load_more_api_call', null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      debugPrint('Failed to load more posts: $e');
      
      // エラー時もパフォーマンス測定を終了
      _logPerformanceMetrics('load_more_api_call', null);
    }
  }

  /// リフレッシュ専用のタイムライン読み込み（既存データを保持）
  Future<void> _loadTimelineForRefresh() async {
    debugPrint('📱 Loading timeline for refresh (preserving existing data)');
    
    _startPerformanceTimer('refresh_timeline_load_api_call');

    try {
      // Use the deck's account if specified, otherwise fall back to active account
      final String? accountDid;
      if (widget.deck.accountDid != null && !widget.deck.isCrossAccount) {
        // Use the specific account for this deck
        accountDid = widget.deck.accountDid;
        debugPrint('📱 Refreshing timeline for deck account: $accountDid');
      } else {
        // Cross-account deck or no specific account - use active account
        final activeAccount = ref.read(activeAccountProvider);
        if (activeAccount == null) {
          throw Exception('No active account');
        }
        accountDid = activeAccount.did;
        debugPrint('📱 Refreshing timeline for active account: $accountDid');
      }

      final database = ref.read(databaseProvider);
      final blueskyService = BlueskyServiceV2(
        database: database,
        secureStorage: const FlutterSecureStorage(),
        authConfig: const AuthConfig(defaultPdsHost: 'bsky.social'),
      );

      await blueskyService.initialize();

      final response = await blueskyService.getTimelineFeed(
        accountDid: accountDid!,
        limit: 50,
      );

      if (!mounted) return;
      
      // 成功時のみ既存データを新しいデータで置き換え
      setState(() {
        _feedData = response.feed.toList();
        _nextCursor = response.cursor;
        debugPrint('📱 Timeline refreshed successfully: ${_feedData.length} posts (replaced existing data)');
      });
      
      _logPerformanceMetrics('refresh_timeline_load_api_call', null);
    } catch (e) {
      if (!mounted) return;
      
      // エラー時は既存データを保持し、エラー状態のみ更新
      debugPrint('⚠️ Timeline refresh failed (existing data preserved): $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      // エラー時もパフォーマンス測定を終了
      _logPerformanceMetrics('refresh_timeline_load_api_call', null);
    }
  }

  @override
  Widget buildContent() {
    if (_hasError) {
      return _buildErrorState();
    }

    // デバッグログ: ローディング状態を確認
    debugPrint('📱 BuildContent - isLoading: $_isLoading, isRefreshing: $_isRefreshing, feedData.length: ${_feedData.length}');
    
    // リフレッシュローディング表示の詳細ログ
    if (_isRefreshing) {
      debugPrint('📱 REFRESH LOADING: Will show refresh loading indicator at top');
    } else {
      debugPrint('📱 REFRESH LOADING: NOT showing refresh loading (_isRefreshing = false)');
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // オーバースクロール検出による pull-to-refresh
        if (notification is OverscrollNotification) {
          if (notification.overscroll < -30 && !_isRefreshing) {
            // 上方向へ30px以上オーバースクロール時にリフレッシュ
            debugPrint('📱 Pull-to-refresh triggered by overscroll: ${notification.overscroll}');
            refresh();
          }
        }
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Loading indicator at top (for refresh - unified style with enhanced visibility)
          if (_isRefreshing)
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
            
          // Loading indicator at top (for initial load when no data)
          if (_isLoading && _feedData.isEmpty && !_isRefreshing)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).loadingNewPosts,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Real timeline data
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _feedData.length) return null;
                
                final feedView = _feedData[index];
                
                return _buildPostItem(feedView);
              },
              childCount: _feedData.length,
            ),
          ),
          
          // Loading indicator at bottom (for load more when data exists)
          if (_isLoadingMore)
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
      debugPrint('📱 Processing feedView.reason: ${feedView.reason?.runtimeType}');
      feedView.reason!.when(
        repost: (repost) {
          debugPrint('📱 Repost detected from: ${repost.by.handle}');
          repostWidget = SimpleRepostWidget(repost: repost);
        },
        pin: (pin) {
          debugPrint('📱 Pin reason detected (not displaying)');
        },
        unknown: (data) {
          debugPrint('📱 Unknown reason type detected: $data');
        },
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
              onLike: () {
                // TODO: Implement like action
              },
              onRepost: () {
                // TODO: Implement repost action
              },
              onReply: () {
                // TODO: Implement reply action
              },
              onTap: () {
                // TODO: Implement post tap navigation
              },
              onMentionTap: (did) {
                debugPrint('📱 Mention tapped: $did');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).richTextMentionTapped(did)),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context).richTextProfileView,
                      onPressed: () {
                        debugPrint('🔍 Profile view: $did');
                        // TODO: プロフィール表示機能の実装
                      },
                    ),
                  ),
                );
              },
              onLinkTap: (url) {
                debugPrint('📱 Link tapped: $url');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).richTextUrlTapped(url)),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context).richTextOpenUrl,
                      onPressed: () {
                        debugPrint('🔗 Open URL: $url');
                        // TODO: URLを開く機能の実装
                      },
                    ),
                  ),
                );
              },
              onHashtagTap: (tag) {
                debugPrint('📱 Hashtag tapped: $tag');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).richTextHashtagTapped(tag)),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context).richTextHashtagSearch,
                      onPressed: () {
                        debugPrint('🔍 Hashtag search: $tag');
                        // TODO: ハッシュタグ検索機能の実装
                      },
                    ),
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

  @override
  Future<void> refresh() async {
    if (!mounted || _isRefreshing) {
      debugPrint('📱 Timeline refresh SKIPPED: mounted=$mounted, isRefreshing=$_isRefreshing');
      return;
    }
    
    debugPrint('📱 Pull-to-Refresh: Timeline refresh initiated (preserving existing posts)');
    
    setState(() {
      _isRefreshing = true;
      _hasError = false;
      debugPrint('📱 Pull-to-Refresh: REFRESH FLAG SET: _isRefreshing = true');
    });
    
    try {
      // リフレッシュ専用のタイムライン読み込み
      await _loadTimelineForRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          debugPrint('📱 REFRESH FLAG RESET: _isRefreshing = false');
        });
      } else {
        debugPrint('📱 REFRESH COMPLETED: Widget not mounted, cannot reset flag');
      }
    }
  }

  Widget _buildErrorState() {
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
            _errorMessage,
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