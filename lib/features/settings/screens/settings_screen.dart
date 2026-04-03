// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/theme/app_themes.dart';
import 'package:moodesky/features/settings/screens/account_management_screen.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/shared/widgets/common/theme_helpers.dart';
import 'package:moodesky/shared/widgets/language_selector.dart';
import 'package:moodesky/shared/widgets/theme_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.appTextStyles;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).appearanceSettings,
                    style: textStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Theme Selection
                  const ThemeSelector(),

                  const SizedBox(height: 24),

                  // Language Selection
                  const LanguageSelector(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Account Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).accountSettings,
                    style: textStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.manage_accounts),
                    title: Text(
                      AppLocalizations.of(context).manageAccounts,
                      style: TextStyle(
                        color: context.isLight
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF5F5F5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context).manageAccountsDescription,
                      style: TextStyle(
                        color: context.isLight
                            ? const Color(0xFF222222)
                            : const Color(0xFFE0E0E0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AccountManagementScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: Icon(
                      Icons.logout, 
                      color: Theme.of(context).colorScheme.strongErrorColor,
                    ),
                    title: Text(
                      AppLocalizations.of(context).signOutAll,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.strongErrorColor,
                        fontWeight: FontWeight.w600, // フォントウェイトも少し上げる
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context).signOutAllDescription,
                      style: TextStyle(
                        color: context.isLight
                            ? const Color(0xFF222222)
                            : const Color(0xFFE0E0E0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => _showSignOutConfirmation(context, ref),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Information Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).appInformation,
                    style: textStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(
                      AppLocalizations.of(context).aboutApp,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF5F5F5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context).appVersion('0.0.1'),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF222222)
                            : const Color(0xFFE0E0E0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: Text(
                      AppLocalizations.of(context).privacyPolicy,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF5F5F5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      // TODO: Open privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context).comingSoon,
                          ),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(
                      AppLocalizations.of(context).termsOfService,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF5F5F5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      // TODO: Open terms of service
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context).comingSoon,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).signOutAll();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.strongErrorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).signOutButton),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'moodeSky',
      applicationVersion: '0.0.1',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.cloud,
          size: 32,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      children: [Text(AppLocalizations.of(context).aboutAppDescription)],
    );
  }
}
