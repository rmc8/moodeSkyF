import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/providers/bluesky_service_provider.dart';
import 'package:moodesky/services/database/database.dart';

/// State for a single timeline deck
class TimelineState {
  final List<bsky.FeedView> posts;
  final String? cursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? error;

  const TimelineState({
    this.posts = const [],
    this.cursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.error,
  });

  TimelineState copyWith({
    List<bsky.FeedView>? posts,
    String? cursor,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? error,
  }) {
    return TimelineState(
      posts: posts ?? this.posts,
      cursor: cursor ?? this.cursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
    );
  }
}

/// Family notifier to manage timeline state per deck
final timelineProvider = StateNotifierProvider.family<TimelineNotifier, TimelineState, Deck>((ref, deck) {
  return TimelineNotifier(ref, deck);
});

class TimelineNotifier extends StateNotifier<TimelineState> {
  final Ref ref;
  final Deck deck;

  TimelineNotifier(this.ref, this.deck) : super(const TimelineState());

  /// どのアカウントを使用してタイムラインを取得するかを決定
  String? _getEffectiveAccountDid() {
    if (deck.accountDid != null && !deck.isCrossAccount) {
      return deck.accountDid;
    } else {
      final activeAccount = ref.read(activeAccountProvider);
      return activeAccount?.did;
    }
  }

  /// 初期データ読み込み
  Future<void> loadInitial() async {
    if (state.posts.isNotEmpty || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final accountDid = _getEffectiveAccountDid();
      if (accountDid == null) throw Exception('No active account');

      final service = ref.read(blueskyServiceProvider);
      await service.initialize();

      final response = await service.getTimelineFeed(
        accountDid: accountDid,
        limit: 100,
      );

      state = state.copyWith(
        posts: response.feed.toList(),
        cursor: response.cursor,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 追加読み込み (Infinite Scroll)
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.cursor == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final accountDid = _getEffectiveAccountDid();
      if (accountDid == null) throw Exception('No active account');

      final service = ref.read(blueskyServiceProvider);
      await service.initialize();

      final response = await service.getTimelineFeed(
        accountDid: accountDid,
        cursor: state.cursor,
        limit: 100,
      );

      // 重複排除ロジック
      final currentCids = state.posts.map((p) => p.post.cid).toSet();
      final newPosts = response.feed.where((p) => !currentCids.contains(p.post.cid)).toList();

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        cursor: response.cursor,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      debugPrint('Failed to load more: $e');
    }
  }

  /// リフレッシュ
  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true);

    try {
      final accountDid = _getEffectiveAccountDid();
      if (accountDid == null) throw Exception('No active account');

      final service = ref.read(blueskyServiceProvider);
      await service.initialize();

      final response = await service.getTimelineFeed(
        accountDid: accountDid,
        limit: 100,
      );

      state = state.copyWith(
        posts: response.feed.toList(),
        cursor: response.cursor,
        isRefreshing: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: e.toString());
    }
  }
}
