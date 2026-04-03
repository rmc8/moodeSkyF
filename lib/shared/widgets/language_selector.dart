// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/locale_provider.dart';
import 'package:moodesky/l10n/app_localizations.dart';

/// 言語選択ウィジェット
class LanguageSelector extends ConsumerWidget {
  final bool showLabel;
  final bool isCompact;

  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLocale = ref.watch(localeNotifierProvider);

    return asyncLocale.when(
      data: (currentLocale) => isCompact
          ? _buildCompactSelector(context, ref, currentLocale)
          : _buildFullSelector(context, ref, currentLocale),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) =>
          Icon(Icons.error, color: Theme.of(context).colorScheme.error),
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    return PopupMenuButton<Locale>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            SupportedLocales.getFlag(currentLocale),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
      onSelected: (locale) => _changeLanguage(ref, locale),
      itemBuilder: (context) => SupportedLocales.locales.map((locale) {
        final isSelected = locale == currentLocale;
        return PopupMenuItem<Locale>(
          value: locale,
          child: Row(
            children: [
              Text(
                SupportedLocales.getFlag(locale),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                SupportedLocales.getDisplayName(locale),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
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
    Locale currentLocale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            AppLocalizations.of(context).languageLabel,
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
            child: DropdownButton<Locale>(
              value: currentLocale,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onChanged: (locale) => _changeLanguage(ref, locale!),
              items: SupportedLocales.locales.map((locale) {
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Row(
                    children: [
                      Text(
                        SupportedLocales.getFlag(locale),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(SupportedLocales.getDisplayName(locale)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          AppLocalizations.of(context).languageDescription,
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

  void _changeLanguage(WidgetRef ref, Locale locale) {
    ref.read(localeNotifierProvider.notifier).setLocale(locale);
  }
}

/// 言語選択ダイアログ
class LanguageSelectionDialog extends ConsumerWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLocale = ref.watch(localeNotifierProvider);

    return asyncLocale.when(
      data: (currentLocale) => AlertDialog(
        title: Text(AppLocalizations.of(context).selectLanguage),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: SupportedLocales.locales.map((locale) {
              final isSelected = locale == currentLocale;
              return ListTile(
                leading: Text(
                  SupportedLocales.getFlag(locale),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  SupportedLocales.getDisplayName(locale),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(localeNotifierProvider.notifier).setLocale(locale);
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
}
