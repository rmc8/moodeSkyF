// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/features/home/widgets/add_deck_dialog.dart';
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/shared/models/auth_models.dart';
import 'package:moodesky/shared/widgets/common/theme_helpers.dart';
import 'deck_utils.dart';

/// Desktop/Tablet tab bar for deck management
class DeckTabBar extends ConsumerStatefulWidget {
  final List<Deck> decks;
  final int selectedTabIndex;
  final Function(int) onTabSelected;
  final Function(int, int, List<Deck>) onDeckMoved;

  const DeckTabBar({
    super.key,
    required this.decks,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.onDeckMoved,
  });

  @override
  ConsumerState<DeckTabBar> createState() => _DeckTabBarState();
}

class _DeckTabBarState extends ConsumerState<DeckTabBar> {
  final ScrollController _tabScrollController = ScrollController();
  bool _isDragging = false;

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.appColors.getGlassColor(context, opacity: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Tab scroll view with drag & drop support
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                // モバイルでのドラッグ体験を改善
                scrollbarTheme: ScrollbarThemeData(
                  thumbVisibility: WidgetStateProperty.all(false),
                ),
              ),
              child: ReorderableListView.builder(
                scrollController: _tabScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 12),
                itemCount: widget.decks.length,
                // モバイルでの長押し時間を短縮（デフォルト500ms → 300ms）
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  // ドラッグ中の視覚的フィードバック改善
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final elevation = Tween<double>(
                        begin: 0.0,
                        end: 8.0,
                      ).evaluate(animation);
                      final scale = Tween<double>(
                        begin: 1.0,
                        end: 1.05,
                      ).evaluate(animation);
                      
                      return Transform.scale(
                        scale: scale,
                        child: Material(
                          elevation: elevation,
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                          child: child,
                        ),
                      );
                    },
                    child: child,
                  );
                },
                onReorderStart: (index) {
                  setState(() {
                    _isDragging = true;
                  });
                  // モバイルでのハプティックフィードバック
                  HapticFeedback.lightImpact();
                },
                onReorderEnd: (index) {
                  setState(() {
                    _isDragging = false;
                  });
                  // ドラッグ終了時のフィードバック
                  HapticFeedback.mediumImpact();
                },
                onReorder: (oldIndex, newIndex) {
                  widget.onDeckMoved(oldIndex, newIndex, widget.decks);
                },
                itemBuilder: (context, index) {
                  final deck = widget.decks[index];
                  final isSelected = widget.selectedTabIndex == index;
                  
                  return ReorderableDragStartListener(
                    key: ValueKey(deck.deckId),
                    index: index,
                    child: Material(
                      color: Colors.transparent,
                      child: _buildTab(deck, index, isSelected),
                    ),
                  );
                },
              ),
            ),
          ),

          // Add deck button
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddDeckDialog(),
                );
              },
              // tooltip: 'Add Deck', // モバイルでのドラッグ操作を妨げないように無効化
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(Deck deck, int index, bool isSelected) {
    final allAccounts = ref.watch(availableAccountsProvider);
    final activeAccount = ref.watch(activeAccountProvider);

    // デッキに関連付けられたアカウントを取得
    var account = deck.accountDid != null
        ? allAccounts.firstWhereOrNull((a) => a.did == deck.accountDid)
        : null;

    // 対応するアカウントが見つからない場合はアクティブアカウントを使用
    account ??= activeAccount;

    return GestureDetector(
      onTap: () {
        if (!_isDragging) {
          widget.onTabSelected(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: context.isLight ? 0.7 : 0.3)
              : context.appColors.getGlassColor(context, opacity: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            width: 1.2,
          ) : Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getDeckIcon(deck.deckType),
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: _buildTabContent(context, deck, account, isSelected),
              ),
              // Close button
              GestureDetector(
                onTap: () {
                  DeckUtils.handleDeckMenuAction(
                    context,
                    ref,
                    'delete',
                    deck,
                    index,
                    widget.decks.length,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, Deck deck, UserProfile? account, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // タイトル
        Expanded(
          child: Text(
            deck.title.length > 18 ? '${deck.title.substring(0, 18)}...' : deck.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        // アカウントアバター（アカウント情報がある場合のみ）
        if (account != null) ...[
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 8,
            backgroundImage: account.avatar != null ? NetworkImage(account.avatar!) : null,
            backgroundColor: account.avatar == null ? _getAccountColor(account.did) : null,
            child: account.avatar == null ? Text(
              account.handle.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ) : null,
          ),
        ] else if (deck.isCrossAccount) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.group_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ],
    );
  }

  IconData _getDeckIcon(String deckType) {
    switch (deckType) {
      case 'home':
        return Icons.home_rounded;
      case 'notifications':
        return Icons.notifications_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'list':
        return Icons.list_rounded;
      case 'profile':
        return Icons.person_rounded;
      case 'thread':
        return Icons.forum_rounded;
      case 'custom_feed':
        return Icons.tag_rounded;
      case 'local':
        return Icons.people_rounded;
      case 'hashtag':
        return Icons.tag_rounded;
      case 'mentions':
        return Icons.alternate_email_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  Color _getAccountColor(String did) {
    final hash = did.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}