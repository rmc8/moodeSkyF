// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/theme/app_themes.dart';
import 'package:moodesky/features/auth/models/server_config.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/shared/models/auth_models.dart';
import 'package:moodesky/shared/widgets/common/index.dart';
import 'package:moodesky/shared/widgets/language_selector.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialIdentifier;
  final ServerConfig? initialServer;
  final bool isReauth;

  const LoginScreen({
    super.key,
    this.initialIdentifier,
    this.initialServer,
    this.isReauth = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  ServerConfig _selectedServer = ServerPresets.blueskyOfficial;

  @override
  void initState() {
    super.initState();

    // 初期値を設定
    if (widget.initialIdentifier != null) {
      _identifierController.text = widget.initialIdentifier!;
    }

    if (widget.initialServer != null) {
      _selectedServer = widget.initialServer!;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // App password sign in only
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithAppPassword(
            identifier: _identifierController.text.trim(),
            password: _passwordController.text,
          );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Show loading if auth is in progress
    if (authState is AuthLoading) {
      return Scaffold(
        body: LoadingIndicators.standard(
          message: AppLocalizations.of(context).signingIn,
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppThemes.getSystemUiOverlayStyle(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: AppThemes.getSystemUiOverlayStyle(context),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: LanguageSelector(isCompact: true, showLabel: false),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            Text(
                              'moodeSky',
                              style: context.appTextStyles.headlineLarge
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.appColors.primary,
                                  ),
                            ),
                            if (widget.isReauth) ...[
                              const SizedBox(height: 8),
                              Text(
                                '再認証',
                                style: context.appTextStyles.titleMedium
                                    .copyWith(
                                      color: context.appColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Auth method toggle
                      CommonContainerFactories.card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).loginMethod,
                              style: context.appTextStyles.titleMedium,
                            ),
                            AppSpacing.verticalSpacerSM,
                            // App Password info
                            CommonContainer(
                              style: CommonContainerStyle.none,
                              padding: AppSpacing.paddingMD,
                              color: context.appColors.infoWithOpacity,
                              borderRadius: AppBorderRadius.smRadius,
                              border: Border.all(
                                color: context.appColors.info.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: context.appColors.info,
                                    size: 16,
                                  ),
                                  AppSpacing.horizontalSpacerSM,
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.appPasswordRecommended,
                                      style: context.appTextStyles.bodySmall
                                          .copyWith(
                                            color: context.appColors.info,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Server selection
                      CommonContainerFactories.card(
                        child: ExpansionTile(
                          leading: Icon(
                            _selectedServer.isOfficial
                                ? Icons.verified
                                : Icons.dns,
                            color: _selectedServer.isOfficial
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                          title: Text(_selectedServer.displayName),
                          subtitle: Text(
                            Uri.parse(_selectedServer.serviceUrl).host,
                          ),
                          children: [
                            for (final server
                                in ServerPresets.predefinedServers)
                              Builder(
                                builder: (context) {
                                  final isSelected =
                                      server.serviceUrl ==
                                      _selectedServer.serviceUrl;
                                  return ListTile(
                                    leading: Icon(
                                      server.isOfficial
                                          ? Icons.verified
                                          : Icons.dns,
                                      color: server.isOfficial
                                          ? Colors.blue
                                          : Colors.grey[600],
                                    ),
                                    title: Text(
                                      server.displayName,
                                      style: TextStyle(
                                        fontWeight: server.isOfficial
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      Uri.parse(server.serviceUrl).host,
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.blue,
                                          )
                                        : null,
                                    selected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedServer = server;
                                      });
                                    },
                                  );
                                },
                              ),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.customServerOption,
                              ),
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                )!.customServerDescription,
                              ),
                              onTap: () {
                                // TODO: カスタムサーバー追加ダイアログ
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.customServerComingSoon,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Identifier field
                      TextFormField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.identifierLabel,
                          hintText: AppLocalizations.of(
                            context,
                          )!.identifierHint,
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return AppLocalizations.of(
                              context,
                            )!.identifierRequired;
                          }
                          return null;
                        },
                      ),

                      // Password field
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.passwordLabel,
                          hintText: AppLocalizations.of(context).passwordHint,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return AppLocalizations.of(
                              context,
                            )!.passwordRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      // App Password help and warning
                      CommonContainer(
                        style: CommonContainerStyle.none,
                        padding: AppSpacing.paddingMD,
                        color: context.appColors.infoWithOpacity,
                        borderRadius: AppBorderRadius.smRadius,
                        border: Border.all(
                          color: context.appColors.info.withValues(alpha: 0.3),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: context.appColors.info,
                                  size: 16,
                                ),
                                AppSpacing.horizontalSpacerSM,
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.aboutAppPassword,
                                  style: context.appTextStyles.labelSmall
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.info,
                                      ),
                                ),
                              ],
                            ),
                            AppSpacing.verticalSpacerXS,
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.appPasswordDescription,
                              style: context.appTextStyles.caption,
                            ),
                            AppSpacing.verticalSpacerSM,
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _selectedServer.appPasswordUrl,
                                    ),
                                    action: SnackBarAction(
                                      label: AppLocalizations.of(
                                        context,
                                      )!.copyButton,
                                      onPressed: () {
                                        // TODO: URLをクリップボードにコピー
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.generateAppPassword,
                                style: context.appTextStyles.caption.copyWith(
                                  color: context.appColors.info,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign in button
                      CommonButtonFactories.primary(
                        onPressed: _signIn,
                        isLoading: _isLoading,
                        width: double.infinity,
                        size: CommonButtonSize.large,
                        child: Text(AppLocalizations.of(context).signInButton),
                      ),

                      // Error display
                      if (authState is AuthError) ...[
                        AppSpacing.verticalSpacerMD,
                        ErrorWidgets.card(
                          title: AppLocalizations.of(context).loginError,
                          message: authState.message,
                          margin: EdgeInsets.zero,
                          onRetry:
                              authState.errorType == AuthErrorType.networkError
                              ? () => ref
                                    .read(authNotifierProvider.notifier)
                                    .refresh()
                              : null,
                          retryLabel: AppLocalizations.of(context).retryButton,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Help text
                      Text(
                        AppLocalizations.of(context).helpTextAppPassword,
                        style: context.appTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
