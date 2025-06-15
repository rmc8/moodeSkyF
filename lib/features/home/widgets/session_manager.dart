// Flutter imports:
import 'dart:async';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:moodesky/core/providers/auth_provider.dart';
import 'package:moodesky/core/providers/session_provider.dart';
import 'package:moodesky/core/utils/session_utils.dart';
import 'package:moodesky/features/auth/screens/add_account_screen.dart';
import 'package:moodesky/l10n/app_localizations.dart';
import 'package:moodesky/shared/models/auth_models.dart';
import 'package:moodesky/shared/models/session_models.dart';

/// セッション管理画面
/// 
/// アカウント切り替えの概念を削除し、各アカウントのセッション管理に特化
class SessionManager extends ConsumerWidget {
  const SessionManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'アカウント管理',
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

          // アカウント一覧
          if (availableAccounts.isNotEmpty)
            ...availableAccounts.map(
              (account) => _buildAccountItem(context, ref, account),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).noLoggedInAccounts,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 新しいアカウント追加ボタン
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

          // 全アカウントサインアウトボタン
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

  Widget _buildAccountItem(
    BuildContext context,
    WidgetRef ref,
    UserProfile account,
  ) {
    final sessionInfo = ref.watch(sessionInfoProvider(account.did));
    final l10n = AppLocalizations.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アカウント基本情報
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: account.avatar != null 
                      ? NetworkImage(account.avatar!) 
                      : null,
                  child: account.avatar == null 
                      ? Text(account.handle.substring(0, 1).toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.displayName ?? account.handle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '@${account.handle}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // セッション状態アイコン
                Icon(
                  SessionUtils.getWarningIcon(sessionInfo?.status.warningLevel ?? SessionWarningLevel.expired),
                  color: SessionUtils.getWarningColor(
                    sessionInfo?.status.warningLevel ?? SessionWarningLevel.expired,
                    Theme.of(context).colorScheme,
                  ),
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // セッション期限表示
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '再認証期限: ${SessionUtils.formatTimeRemaining(sessionInfo?.status.timeRemaining, l10n)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // アクションボタン
            Row(
              children: [
                // 再認証ボタン
                OutlinedButton.icon(
                  onPressed: () => _reauthenticateAccount(context, ref, account),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('再認証'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 8),
                // アカウント削除ボタン
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteAccount(context, ref, account),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('削除'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reauthenticateAccount(
    BuildContext context,
    WidgetRef ref,
    UserProfile account,
  ) {
    _showReauthenticationDialog(context, ref, account);
  }

  void _showReauthenticationDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile account,
  ) {
    final passwordController = TextEditingController();
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('再認証'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${account.displayName ?? account.handle} の再認証を行います。'),
            const SizedBox(height: 16),
            Text(
              'アプリパスワードを入力してください:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'アプリパスワード',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performReauthentication(
                context,
                ref,
                account,
                passwordController.text,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => _performReauthentication(
              context,
              ref,
              account,
              passwordController.text,
            ),
            child: const Text('再認証'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReauthentication(
    BuildContext context,
    WidgetRef ref,
    UserProfile account,
    String password,
  ) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードを入力してください'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(); // Close dialog

    // ダイアログのcontextを保存するための変数
    BuildContext? dialogContext;
    bool dialogShown = false;

    // Show enhanced loading indicator with explicit dialog management
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context; // ダイアログのcontextを保存
        dialogShown = true;
        
        debugPrint('🔄 [UI] Loading dialog created, context: ${context.hashCode}');
        
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button during auth
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('${account.displayName ?? account.handle}を再認証中...'),
                const SizedBox(height: 8),
                const Text(
                  'しばらくお待ちください',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // ダイアログの表示が完了するまで少し待機
    debugPrint('🕐 [UI] Waiting for dialog to be fully displayed...');
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('✅ [UI] Dialog should now be displayed');

    try {
      debugPrint('🔄 [AUTH] Starting authentication process...');
      debugPrint('🔍 [AUTH] Dialog context mounted: ${dialogShown && dialogContext?.mounted == true}');
      
      // Perform authentication with timeout using a more reliable approach
      late AuthResult authResult;
      bool authCompleted = false;
      
      // タイムアウト付きで認証実行
      await Future.any([
        () async {
          try {
            authResult = await ref.read(authNotifierProvider.notifier).reauthenticateAccount(
              accountDid: account.did,
              password: password,
            );
            authCompleted = true;
            debugPrint('✅ [AUTH] Authentication completed successfully');
          } catch (e) {
            debugPrint('❌ [AUTH] Authentication failed: $e');
            rethrow;
          }
        }(),
        Future.delayed(
          const Duration(seconds: 30),
          () {
            if (!authCompleted) {
              debugPrint('⏰ [AUTH] Authentication timed out');
              throw TimeoutException('認証がタイムアウトしました', const Duration(seconds: 30));
            }
          },
        ),
      ]);

      // ダイアログを確実に閉じる - 元のcontextを優先
      if (context.mounted) {
        debugPrint('🔄 [UI] Closing loading dialog using original context');
        Navigator.of(context).pop();
        debugPrint('✅ [UI] Loading dialog closed with original context');
      } else if (dialogShown && dialogContext?.mounted == true) {
        debugPrint('🔄 [UI] Closing loading dialog using dialog context');
        Navigator.of(dialogContext!).pop();
        debugPrint('✅ [UI] Loading dialog closed with dialog context');
      } else {
        debugPrint('❌ [UI] No valid context available to close dialog!');
      }

      // 認証結果の処理
      if (context.mounted && authCompleted) {
        debugPrint('🔄 [UI] Processing authentication result...');
        
        authResult.when(
          success: (session, accountDid) {
            debugPrint('✅ [AUTH] Success case - updating session state');
            
            // Update session state immediately with retry mechanism
            try {
              ref.read(sessionInfoNotifierProvider.notifier).refreshSessionForAccount(accountDid);
              debugPrint('✅ [STATE] Session state updated successfully');
            } catch (e) {
              debugPrint('❌ [STATE] Failed to update session state: $e');
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${account.displayName ?? account.handle}の再認証が完了しました')),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          failure: (error, errorDescription, errorType) {
            debugPrint('❌ [AUTH] Failure case: $error');
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('再認証に失敗しました: $error')),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '再試行',
                  textColor: Colors.white,
                  onPressed: () => _reauthenticateAccount(context, ref, account),
                ),
              ),
            );
          },
          cancelled: () {
            debugPrint('⚠️ [AUTH] Cancelled case');
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('再認証がキャンセルされました'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('⏰ [AUTH] Authentication timeout: $e');
      
      // ダイアログを確実に閉じる - 元のcontextを優先
      if (context.mounted) {
        debugPrint('🔄 [UI] Closing loading dialog using original context (timeout)');
        Navigator.of(context).pop();
      } else if (dialogShown && dialogContext?.mounted == true) {
        debugPrint('🔄 [UI] Closing loading dialog using dialog context (timeout)');
        Navigator.of(dialogContext!).pop();
      } else {
        debugPrint('❌ [UI] No valid context available to close dialog (timeout)!');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.timer_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('認証がタイムアウトしました。ネットワーク接続を確認してください。')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _reauthenticateAccount(context, ref, account),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [AUTH] Unexpected error: $e');
      
      // ダイアログを確実に閉じる - 元のcontextを優先
      if (context.mounted) {
        debugPrint('🔄 [UI] Closing loading dialog using original context (error)');
        Navigator.of(context).pop();
      } else if (dialogShown && dialogContext?.mounted == true) {
        debugPrint('🔄 [UI] Closing loading dialog using dialog context (error)');
        Navigator.of(dialogContext!).pop();
      } else {
        debugPrint('❌ [UI] No valid context available to close dialog (error)!');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('予期しないエラーが発生しました: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: () => _reauthenticateAccount(context, ref, account),
            ),
          ),
        );
      }
    }
  }

  void _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    UserProfile account,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウント削除の確認'),
        content: Text('${account.displayName ?? account.handle}を削除しますか？\\n\\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(ref, account);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(WidgetRef ref, UserProfile account) {
    ref.read(authNotifierProvider.notifier).removeAccount(account.did);
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
              Navigator.of(context).pop(); // Close session manager
              await ref.read(authNotifierProvider.notifier).signOutAll();
            },
            child: Text(AppLocalizations.of(context).signOutButton),
          ),
        ],
      ),
    );
  }
}