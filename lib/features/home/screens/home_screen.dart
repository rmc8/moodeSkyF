// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/providers/deck_provider.dart';
import 'package:moodesky/core/providers/theme_provider.dart';
import 'package:moodesky/core/theme/app_themes.dart';
import 'package:moodesky/features/home/widgets/add_deck_dialog.dart';
import 'package:moodesky/features/home/widgets/deck_layout.dart';
import 'package:moodesky/features/home/widgets/deck_layout/timeline/bluesky_timeline_widget.dart';
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/features/settings/screens/settings_screen.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/shared/models/auth_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // ホーム画面表示時に必要に応じてプロフィール情報を更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfilesIfNeeded();
    });
  }

  // 必要に応じてプロフィール情報を更新
  Future<void> _refreshProfilesIfNeeded() async {
    try {
      await ref.read(authNotifierProvider.notifier).refreshProfilesIfNeeded();
    } catch (e) {
      // エラーは無視（UIブロックを避ける）
      debugPrint('Failed to refresh profiles in HomeScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // テーマ変更を監視して確実に更新されるようにする
    final currentTheme = ref.watch(currentThemeModeProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppThemes.getSystemUiOverlayStyle(context),
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar (for desktop/tablet)
            if (MediaQuery.of(context).size.width >= 1200) ...[
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Logged-in accounts header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).appTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildLoggedInAccounts(),
                        ],
                      ),
                    ),
                    const Divider(),

                    // Navigation
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          _buildNavItem(
                            context,
                            icon: Icons.home,
                            label: AppLocalizations.of(context).homeNavigation,
                            isSelected: true,
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.notifications,
                            label: AppLocalizations.of(
                              context,
                            ).notificationsNavigation,
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.search,
                            label: AppLocalizations.of(
                              context,
                            ).searchNavigation,
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.person,
                            label: AppLocalizations.of(
                              context,
                            ).profileNavigation,
                          ),
                          const Divider(),
                          _buildNavItem(
                            context,
                            icon: Icons.add_box,
                            label: AppLocalizations.of(context).addDeckButton,
                            onTap: () => _showAddDeckDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Main content area - Deck layout (no AppBar)
            Expanded(
              child: SafeArea(
                child: _buildDeckLayout(currentTheme),
              ),
            ),
          ],
        ),

        // Bottom navigation (all devices except desktop)
        bottomNavigationBar: MediaQuery.of(context).size.width < 1200
            ? _buildBottomNavigationBar()
            : null,
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isSelected,
      onTap:
          onTap ??
          () {
            // TODO: Handle navigation
          },
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _showAddDeckDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddDeckDialog());
  }

  void _showComposeDialog(BuildContext context) {
    // TODO: Implement compose dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).composeFunctionUnderDev),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      // Tablet: Extended navigation bar with more options
      return NavigationBar(
        selectedIndex: 0, // Home is always selected for now
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: AppLocalizations.of(context).homeNavigation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_box),
            label: AppLocalizations.of(context).addDeckButton,
            tooltip: AppLocalizations.of(context).addDeckTooltip,
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit),
            label: AppLocalizations.of(context).composeNavigation,
            tooltip: AppLocalizations.of(context).composeTooltip,
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: AppLocalizations.of(context).notificationsNavigation,
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: AppLocalizations.of(context).searchNavigation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context).settingsTitle,
            tooltip: AppLocalizations.of(context).settingsTooltip,
          ),
        ],
        onDestinationSelected: (index) => _handleNavigationTap(index),
      );
    } else {
      // Mobile: Compact navigation bar
      return NavigationBar(
        selectedIndex: 0, // Home is always selected for now
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: AppLocalizations.of(context).homeNavigation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_box),
            label: AppLocalizations.of(context).deckNavigation,
            tooltip: AppLocalizations.of(context).addDeckTooltip,
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit),
            label: AppLocalizations.of(context).composeNavigation,
            tooltip: AppLocalizations.of(context).composeTooltip,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context).settingsTitle,
            tooltip: AppLocalizations.of(context).settingsTooltip,
          ),
        ],
        onDestinationSelected: (index) => _handleNavigationTap(index),
      );
    }
  }

  void _handleNavigationTap(int index) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      // Tablet navigation handling
      switch (index) {
        case 0: // Home - already here
          break;
        case 1: // Add Deck
          _showAddDeckDialog(context);
          break;
        case 2: // Compose
          _showComposeDialog(context);
          break;
        case 3: // Notifications
          // TODO: Navigate to notifications
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).notificationsFunctionUnderDev,
              ),
            ),
          );
          break;
        case 4: // Search
          // TODO: Navigate to search
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).searchFunctionUnderDev,
              ),
            ),
          );
          break;
        case 5: // Settings
          _navigateToSettings(context);
          break;
      }
    } else {
      // Mobile navigation handling
      switch (index) {
        case 0: // Home - already here
          break;
        case 1: // Add Deck
          _showAddDeckDialog(context);
          break;
        case 2: // Compose
          _showComposeDialog(context);
          break;
        case 3: // Settings
          _navigateToSettings(context);
          break;
      }
    }
  }

  Widget _buildLoggedInAccounts() {
    final accounts = ref.watch(availableAccountsProvider);

    if (accounts.isEmpty) {
      return Text(
        AppLocalizations.of(context).noLoggedInAccounts,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: accounts.map((account) {
        return Chip(
          avatar: account.avatar != null
              ? CircleAvatar(backgroundImage: NetworkImage(account.avatar!))
              : CircleAvatar(
                  child: Text(account.handle.substring(0, 1).toUpperCase()),
                ),
          label: Text('@${account.handle}'),
          labelStyle: Theme.of(context).textTheme.bodySmall,
        );
      }).toList(),
    );
  }

  // デッキレイアウトの構築
  Widget _buildDeckLayout(AppThemeMode? currentTheme) {
    final decksAsync = ref.watch(allDecksProvider);

    return decksAsync.when(
      data: (decks) {
        if (decks.isEmpty) {
          return _buildEmptyState();
        }

        // Safety check: Ensure _selectedTabIndex is within bounds
        if (_selectedTabIndex >= decks.length) {
          _selectedTabIndex = decks.length - 1;
        }
        if (_selectedTabIndex < 0) {
          _selectedTabIndex = 0;
        }

        final screenWidth = MediaQuery.of(context).size.width;
        
        if (screenWidth >= 600) {
          // Tablet and Desktop: Show tab bar at top
          return Column(
            children: [
              DeckTabBar(
                decks: decks,
                selectedTabIndex: _selectedTabIndex,
                onTabSelected: _onTabSelected,
                onDeckMoved: _onDeckMoved,
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: decks.map((deck) => _buildDeckContent(deck)).toList(),
                ),
              ),
            ],
          );
        } else {
          // Mobile: Use swipeable layout
          return MobileLayout(
            key: ValueKey('deck_layout_${currentTheme?.index ?? 0}'),
            decks: decks,
            selectedTabIndex: _selectedTabIndex,
            onTabSelected: _onTabSelected,
            onDeckMoved: _onDeckMoved,
            buildDeckContent: _buildDeckContent,
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
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
              'Error loading decks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(allDecksProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // 空状態の表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'デッキがありません',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '最初のデッキを作成してタイムラインを表示しましょう',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddDeckDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Deck'),
          ),
        ],
      ),
    );
  }

  // タブ選択時のコールバック
  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  // デッキ移動時のコールバック
  void _onDeckMoved(int oldIndex, int newIndex, List<Deck> decks) {
    // Immediately update UI state
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Update selected index if needed
    if (_selectedTabIndex == oldIndex) {
      setState(() {
        _selectedTabIndex = newIndex;
      });
    } else if (_selectedTabIndex > oldIndex && _selectedTabIndex <= newIndex) {
      setState(() {
        _selectedTabIndex -= 1;
      });
    } else if (_selectedTabIndex < oldIndex && _selectedTabIndex >= newIndex) {
      setState(() {
        _selectedTabIndex += 1;
      });
    }

    // Update deck order in database
    final updater = ref.read(deckOrderUpdaterProvider);
    final deck = decks[oldIndex];
    updater.updateOrder(deck.deckId, newIndex);
  }

  // デッキコンテンツの構築
  Widget _buildDeckContent(Deck deck) {
    switch (deck.deckType) {
      case 'home':
        return _buildHomeTimelineDeck(deck);
      case 'notifications':
        return _buildNotificationsList();
      case 'profile':
        return _buildProfilePostsList();
      case 'search':
        return _buildSearchResults();
      default:
        return _buildGenericDeckContent(deck);
    }
  }

  // ホームタイムラインデッキの構築
  Widget _buildHomeTimelineDeck(Deck deck) {
    return BlueskyTimelineWidget(
      deck: deck,
      showScrollButtons: true,
    );
  }

  // 通知リストの構築
  Widget _buildNotificationsList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_rounded, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Notifications will appear here'),
        ],
      ),
    );
  }

  // プロフィール投稿リストの構築
  Widget _buildProfilePostsList() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_rounded, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('Profile Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Profile posts will appear here'),
        ],
      ),
    );
  }

  // 検索結果の構築
  Widget _buildSearchResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: Colors.purple),
          SizedBox(height: 16),
          Text('Search Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Search results will appear here'),
        ],
      ),
    );
  }

  // 汎用デッキコンテンツの構築
  Widget _buildGenericDeckContent(Deck deck) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getDeckIcon(deck.deckType),
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            deck.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Content for ${deck.deckType} deck',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }


  // ホームタイムラインコンテンツ
  Widget _buildHomeTimelineContent(Deck deck) {
    return BlueskyTimelineWidget(
      deck: deck,
      showScrollButtons: true,
    );
  }

  // 通知コンテンツ（仮実装）
  Widget _buildNotificationsContent(Deck deck) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Notifications feature is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 検索コンテンツ（仮実装）
  Widget _buildSearchContent(Deck deck) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Search',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Search feature is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // プロフィールコンテンツ（仮実装）
  Widget _buildProfileContent(Deck deck) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Profile feature is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // リストコンテンツ（仮実装）
  Widget _buildListContent(Deck deck) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'List',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'List feature is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // カスタムフィードコンテンツ（仮実装）
  Widget _buildCustomFeedContent(Deck deck) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Custom Feed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Custom feed feature is under development',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // デフォルトコンテンツ
  Widget _buildDefaultContent(Deck deck) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getDeckIcon(deck.deckType),
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              deck.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This deck type (${deck.deckType}) is not yet implemented',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // デッキアイコンの取得
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
}
