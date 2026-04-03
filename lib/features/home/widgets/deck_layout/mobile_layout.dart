// Flutter imports:
import 'dart:ui';
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/providers/deck_provider.dart';
import 'package:moodesky/features/home/widgets/add_deck_dialog.dart';
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/shared/models/auth_models.dart';
import 'deck_utils.dart';

/// Mobile-specific layout for deck management
class MobileLayout extends ConsumerStatefulWidget {
  final List<Deck> decks;
  final int selectedTabIndex;
  final Function(int) onTabSelected;
  final Function(int, int, List<Deck>) onDeckMoved;
  final Widget Function(Deck) buildDeckContent;

  const MobileLayout({
    super.key,
    required this.decks,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.onDeckMoved,
    required this.buildDeckContent,
  });

  @override
  ConsumerState<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<MobileLayout> {
  final ScrollController _tabScrollController = ScrollController();
  late PageController _pageController;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    // 中央付近から開始して循環スワイプを自然にする
    _pageController = PageController(initialPage: 500);
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mobile tab bar with drag & drop
        _buildMobileTabBar(),

        // PageView for deck content with infinite scrolling
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.decks.isEmpty ? 0 : widget.decks.length * 1000,
            onPageChanged: (virtualIndex) {
                if (widget.decks.isEmpty) return;
                if (!_isReordering) {
                  final realIndex = virtualIndex % widget.decks.length;
                  widget.onTabSelected(realIndex);
                  _scrollTabToVisible(realIndex);
                }
              },
            itemBuilder: (context, virtualIndex) {
              if (widget.decks.isEmpty) return const SizedBox.shrink();
              final realIndex = virtualIndex % widget.decks.length;
              final deck = widget.decks[realIndex];
              return _buildMobileDeckPage(deck, realIndex, widget.decks.length);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF1C1C1E).withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
          // Tab scroll view
          Expanded(
            child: ReorderableListView.builder(
              scrollController: _tabScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 8),
              itemCount: widget.decks.length,
              onReorderStart: (index) {
                setState(() {
                  _isReordering = true;
                });
              },
              onReorderEnd: (index) {
                setState(() {
                  _isReordering = false;
                });
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
                  child: _buildMobileTab(deck, index, isSelected, widget.decks),
                );
              },
            ),
          ),

          // Add deck button
          SizedBox(
            width: 44,
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddDeckDialog(),
                );
              },
              tooltip: 'Add Deck',
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildMobileTab(Deck deck, int index, bool isSelected, List<Deck> allDecks) {
    final allAccounts = ref.watch(availableAccountsProvider);
    final activeAccount = ref.watch(activeAccountProvider);

    var account = deck.accountDid != null
        ? allAccounts.firstWhereOrNull((a) => a.did == deck.accountDid)
        : null;
    account ??= activeAccount;

    String tooltipText = deck.title;
    if (account != null) {
      tooltipText += '\n@${account.handle}';
    }

    return GestureDetector(
      onTap: () {
        widget.onTabSelected(index);
        final currentVirtualIndex = (_pageController.page?.round() ?? 500);
        final currentRealIndex = currentVirtualIndex % allDecks.length;
        final targetVirtualIndex = currentVirtualIndex - currentRealIndex + index;

        _pageController.jumpToPage(targetVirtualIndex);
      },
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                _getDeckIcon(deck.deckType),
                size: 20,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildMobileDeckPage(Deck deck, int index, int totalDecks) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          // Mobile deck header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _buildCompactAccountAvatar(deck, isUltraCompact: true),
                if (_hasAccountInfo(deck)) const SizedBox(width: 6),
                Icon(_getDeckIcon(deck.deckType), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deck.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}/$totalDecks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 16),
                    tooltip: 'Deck Options',
                    padding: const EdgeInsets.all(6),
                    onSelected: (value) => DeckUtils.handleDeckMenuAction(
                      context,
                      ref,
                      value,
                      deck,
                      index,
                      totalDecks,
                    ),
                    itemBuilder: (context) => DeckUtils.buildDeckMenuItems(
                      context,
                      index,
                      totalDecks,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Deck content
          Expanded(child: widget.buildDeckContent(deck)),
        ],
      ),
    );
  }

  void _scrollTabToVisible(int index) {
    const double tabWidth = 48.0;
    final double targetOffset = index * tabWidth - (MediaQuery.of(context).size.width / 4);

    _tabScrollController.animateTo(
      targetOffset.clamp(0.0, _tabScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildCompactAccountAvatar(Deck deck, {bool isUltraCompact = false}) {
    final allAccounts = ref.watch(availableAccountsProvider);
    final account = deck.accountDid != null
        ? allAccounts.firstWhereOrNull((a) => a.did == deck.accountDid)
        : null;

    if (account == null) return const SizedBox.shrink();

    final radius = isUltraCompact ? 12.0 : 16.0;

    if (account.avatar != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(account.avatar!),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _getAccountColor(account.did),
        child: Text(
          account.displayName?.substring(0, 1).toUpperCase() ??
              account.handle.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: isUltraCompact ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  bool _hasAccountInfo(Deck deck) {
    final allAccounts = ref.watch(availableAccountsProvider);
    return deck.accountDid != null &&
        allAccounts.any((a) => a.did == deck.accountDid);
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