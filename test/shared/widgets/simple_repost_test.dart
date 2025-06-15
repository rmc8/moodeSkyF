// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:moodesky/shared/utils/user_display_utils.dart';

void main() {
  group('Repost Functionality Tests', () {
    test('UserDisplayUtils.getDisplayName が正しく動作する', () {
      // displayNameがある場合
      final userWithDisplayName = bsky.ActorBasic.fromJson({
        'did': 'did:plc:test',
        'handle': 'test.bsky.social',
        'displayName': 'Test Display Name',
      });
      expect(
        UserDisplayUtils.getDisplayName(userWithDisplayName.displayName, userWithDisplayName.handle),
        equals('Test Display Name'),
      );

      // displayNameがない場合
      final userWithoutDisplayName = bsky.ActorBasic.fromJson({
        'did': 'did:plc:test',
        'handle': 'test.bsky.social',
      });
      expect(
        UserDisplayUtils.getDisplayName(userWithoutDisplayName.displayName, userWithoutDisplayName.handle),
        equals('@test.bsky.social'),
      );

      // displayNameが空文字の場合
      final userWithEmptyDisplayName = bsky.ActorBasic.fromJson({
        'did': 'did:plc:test',
        'handle': 'test.bsky.social',
        'displayName': '',
      });
      expect(
        UserDisplayUtils.getDisplayName(userWithEmptyDisplayName.displayName, userWithEmptyDisplayName.handle),
        equals('@test.bsky.social'),
      );
    });

    test('FeedView ネイティブ型が正しく動作する', () {
      final createdAt = DateTime.now();

      // 通常投稿のFeedView
      final normalFeedView = bsky.FeedView.fromJson({
        'post': {
          'uri': 'at://did:plc:test/app.bsky.feed.post/test123',
          'cid': 'test-cid',
          'author': {
            'did': 'did:plc:test-author',
            'handle': 'testuser.bsky.social',
            'displayName': 'Test User',
          },
          'record': {
            '\$type': 'app.bsky.feed.post',
            'text': 'This is a test post',
            'createdAt': createdAt.toIso8601String(),
            'facets': [],
          },
          'indexedAt': createdAt.toIso8601String(),
          'likeCount': 5,
          'repostCount': 3,
          'replyCount': 2,
          'viewer': {},
        },
      });

      expect(normalFeedView.post.author.handle, equals('testuser.bsky.social'));
      expect(normalFeedView.post.author.displayName, equals('Test User'));
      expect(normalFeedView.reason, isNull);

      // リポスト投稿のFeedView
      final repostFeedView = bsky.FeedView.fromJson({
        'post': normalFeedView.toJson()['post'],
        'reason': {
          '\$type': 'app.bsky.feed.defs#reasonRepost',
          'by': {
            'did': 'did:plc:reposter',
            'handle': 'reposter.bsky.social',
            'displayName': 'Reposter User',
          },
          'indexedAt': createdAt.toIso8601String(),
        },
      });

      expect(repostFeedView.reason, isNotNull);
      repostFeedView.reason!.when(
        repost: (repost) {
          expect(repost.by.handle, equals('reposter.bsky.social'));
          expect(repost.by.displayName, equals('Reposter User'));
        },
        pin: (pin) => fail('Unexpected pin reason'),
        unknown: (data) => fail('Expected repost reason'),
      );
    });
  });
}
