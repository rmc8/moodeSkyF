// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/theme_provider.dart';
import 'package:moodesky/l10n/app_localizations.dart';

/// テーマ選択ウィジェット
class ThemeSelector extends ConsumerWidget {
  final bool showLabel;
  final bool isCompact;

  const ThemeSelector({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThemeMode = ref.watch(themeNotifierProvider);

    return asyncThemeMode.when(
      data: (currentThemeMode) => isCompact
          ? _buildCompactSelector(context, ref, currentThemeMode)
          : _buildFullSelector(context, ref, currentThemeMode),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) =>
          Icon(Icons.error, color: Theme.of(context).colorScheme.error),
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentThemeMode,
  ) {
    return PopupMenuButton<AppThemeMode>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(currentThemeMode.icon, size: 20),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
      onSelected: (themeMode) => _changeTheme(ref, themeMode),
      itemBuilder: (context) => AppThemeMode.values.map((themeMode) {
        final isSelected = themeMode == currentThemeMode;
        return PopupMenuItem<AppThemeMode>(
          value: themeMode,
          child: Row(
            children: [
              Icon(themeMode.icon, size: 18),
              const SizedBox(width: 8),
              Text(_getLocalizedThemeName(context, themeMode)),
              if (isSelected) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullSelector(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentThemeMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            AppLocalizations.of(context).themeLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppThemeMode>(
              value: currentThemeMode,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onChanged: (themeMode) => _changeTheme(ref, themeMode!),
              items: AppThemeMode.values.map((themeMode) {
                return DropdownMenuItem<AppThemeMode>(
                  value: themeMode,
                  child: Row(
                    children: [
                      Icon(themeMode.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(_getLocalizedThemeName(context, themeMode)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          AppLocalizations.of(context).themeDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF222222)
                : const Color(0xFFE0E0E0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getLocalizedThemeName(BuildContext context, AppThemeMode themeMode) {
    final l10n = AppLocalizations.of(context);
    switch (themeMode) {
      case AppThemeMode.light:
        return l10n.themeLight;
      case AppThemeMode.dark:
        return l10n.themeDark;
      case AppThemeMode.system:
        return l10n.themeSystem;
    }
  }

  void _changeTheme(WidgetRef ref, AppThemeMode themeMode) {
    ref.read(themeNotifierProvider.notifier).setThemeMode(themeMode);
  }
}

/// テーマ選択ダイアログ
class ThemeSelectionDialog extends ConsumerWidget {
  const ThemeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThemeMode = ref.watch(themeNotifierProvider);

    return asyncThemeMode.when(
      data: (currentThemeMode) => AlertDialog(
        title: Text(AppLocalizations.of(context).selectTheme),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((themeMode) {
              final isSelected = themeMode == currentThemeMode;
              return ListTile(
                leading: Icon(themeMode.icon, size: 24),
                title: Text(_getLocalizedThemeName(context, themeMode)),
                subtitle: Text(_getThemeDescription(context, themeMode)),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref
                      .read(themeNotifierProvider.notifier)
                      .setThemeMode(themeMode);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancelButton),
          ),
        ],
      ),
      loading: () => const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => AlertDialog(
        title: Text(AppLocalizations.of(context).errorTitle),
        content: Text(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancelButton),
          ),
        ],
      ),
    );
  }

  String _getLocalizedThemeName(BuildContext context, AppThemeMode themeMode) {
    final l10n = AppLocalizations.of(context);
    switch (themeMode) {
      case AppThemeMode.light:
        return l10n.themeLight;
      case AppThemeMode.dark:
        return l10n.themeDark;
      case AppThemeMode.system:
        return l10n.themeSystem;
    }
  }

  String _getThemeDescription(BuildContext context, AppThemeMode themeMode) {
    final l10n = AppLocalizations.of(context);
    switch (themeMode) {
      case AppThemeMode.light:
        return l10n.themeLightDescription;
      case AppThemeMode.dark:
        return l10n.themeDarkDescription;
      case AppThemeMode.system:
        return l10n.themeSystemDescription;
    }
  }
}
