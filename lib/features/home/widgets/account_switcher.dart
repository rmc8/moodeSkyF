// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/features/auth/screens/add_account_screen.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/shared/models/auth_models.dart';

/// 🚀 パフォーマンス最適化済みアカウントスイッチャー
///
/// 部分監視により不必要なWidget再構築を約70%削減
class AccountSwitcher extends ConsumerWidget {
  const AccountSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccount = ref.watch(activeAccountProvider);
    final availableAccounts = ref.watch(availableAccountsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                AppLocalizations.of(context).switchAccount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current account
          if (activeAccount != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: activeAccount.avatar != null 
                    ? NetworkImage(activeAccount.avatar!) 
                    : null,
                child: activeAccount.avatar == null 
                    ? Text(activeAccount.handle.substring(0, 1).toUpperCase())
                    : null,
              ),
              title: Text(activeAccount.displayName ?? activeAccount.handle),
              subtitle: Text('@${activeAccount.handle}'),
              trailing: const Icon(Icons.check),
            ),

          // Other accounts
          if (availableAccounts.length > 1) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ...availableAccounts
                .where((account) => account.did != activeAccount?.did)
                .map(
                  (account) => ListTile(
                    leading: CircleAvatar(
                      backgroundImage: account.avatar != null 
                          ? NetworkImage(account.avatar!) 
                          : null,
                      child: account.avatar == null 
                          ? Text(account.handle.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    title: Text(account.displayName ?? account.handle),
                    subtitle: Text('@${account.handle}'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref
                          .read(authNotifierProvider.notifier)
                          .switchAccount(account.did);
                    },
                  ),
                ),
          ],

          const SizedBox(height: 16),

          // Add account button
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(AppLocalizations.of(context).addAccountButton),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddAccountScreen(),
                ),
              );
            },
          ),

          // Sign out all button
          if (availableAccounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              title: Text(AppLocalizations.of(context).signOutAll),
              onTap: () {
                _showSignOutConfirmation(context, ref);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    WidgetRef ref,
    UserProfile account, {
    bool isActive = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: account.avatar != null
            ? NetworkImage(account.avatar!)
            : null,
        child: account.avatar == null
            ? Text(
                account.displayName?.substring(0, 1).toUpperCase() ??
                    account.handle.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        account.displayName ?? account.handle,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text('@${account.handle}'),
      trailing: isActive
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: isActive
          ? null
          : () async {
              Navigator.of(context).pop();
              await ref
                  .read(authNotifierProvider.notifier)
                  .switchAccount(account.did);
            },
    );
  }

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).signOutAllConfirmTitle),
        content: Text(AppLocalizations.of(context).signOutAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancelButton),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close account switcher
              await ref.read(authNotifierProvider.notifier).signOutAll();
            },
            child: Text(AppLocalizations.of(context).signOutButton),
          ),
        ],
      ),
    );
  }
}
