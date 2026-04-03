// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/providers/locale_provider.dart';
import 'package:moodesky/core/providers/theme_provider.dart';
import 'package:moodesky/core/theme/app_themes.dart';
import 'package:moodesky/features/auth/screens/login_screen.dart';
import 'package:moodesky/features/home/screens/home_screen.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/shared/widgets/common/theme_helpers.dart';

void main() {
  runApp(const ProviderScope(child: MoodeSkyApp()));
}

class MoodeSkyApp extends ConsumerWidget {
  const MoodeSkyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLocale = ref.watch(localeNotifierProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(flutterThemeModeProvider);

    return asyncLocale.when(
      data: (locale) => MaterialApp(
        title: 'moodeSky',
        debugShowCheckedModeBanner: false,

        // Localization
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: SupportedLocales.locales,

        // Theme
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,

        // System UI Overlay Style
        builder: (context, child) {
          AppThemes.setSystemUiOverlayStyle(context);
          return child ?? const SizedBox.shrink();
        },

        // App routing
        home: const AppRouter(),
      ),
      loading: () => MaterialApp(
        title: 'moodeSky',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: SupportedLocales.locales,
        builder: (context, child) {
          AppThemes.setSystemUiOverlayStyle(context);
          return child ?? const SizedBox.shrink();
        },
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => MaterialApp(
        title: 'moodeSky',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: SupportedLocales.locales,
        builder: (context, child) {
          AppThemes.setSystemUiOverlayStyle(context);
          return child ?? const SizedBox.shrink();
        },
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load app: $error'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      initial: () => const LoadingScreen(),
      loading: () => const LoadingScreen(),
      authenticated: (activeAccountDid, accounts, isNewLogin) {
        // ログイン成功通知を表示
        if (isNewLogin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final activeAccount = accounts.firstWhere(
              (account) => account.did == activeAccountDid,
              orElse: () => accounts.first,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).loginSuccess(
                    activeAccount.displayName ?? activeAccount.handle,
                  ),
                ),
                backgroundColor: context.appColors.primary,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: AppLocalizations.of(context).close,
                  textColor: context.appColors.onPrimary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );

            // フラグをリセット（重複表示防止）
            Future.delayed(const Duration(seconds: 1), () {
              ref.read(authNotifierProvider.notifier).clearNewLoginFlag();
            });
          });
        }

        return const HomeScreen();
      },
      unauthenticated: () => const LoginScreen(),
      error: (message, errorType) => ErrorScreen(
        message: message,
        onRetry: () => ref.read(authNotifierProvider.notifier).refresh(),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MoodeSky logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.appColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.cloud,
                size: 64,
                color: context.appColors.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'moodeSky',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).loadingText,
              style: context.appTextStyles.bodyMedium?.copyWith(
                color: context.appColors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorScreen({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: context.appColors.error,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).errorTitle,
                style: context.appTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: context.appTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).retryButton),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
