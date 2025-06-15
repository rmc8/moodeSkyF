// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'moodeSky';

  @override
  String get loginTitle => 'サインイン';

  @override
  String get addAccountTitle => 'アカウントを追加';

  @override
  String get loginMethod => 'サインイン方法';

  @override
  String get authMethodOAuth => 'OAuth';

  @override
  String get authMethodAppPassword => 'アプリパスワード';

  @override
  String get oAuthInfo => 'OAuth機能は開発中です。現在はアプリパスワードをご利用ください。';

  @override
  String get appPasswordRecommended => 'アプリパスワードが推奨されるサインイン方法です。安全で簡単に無効化できます。';

  @override
  String get serverSelectionTitle => 'サーバーを選択';

  @override
  String get customServerOption => 'カスタムサーバー...';

  @override
  String get customServerDescription => 'セルフホストサーバーを追加';

  @override
  String get customServerComingSoon => 'カスタムサーバー機能は開発中です';

  @override
  String get identifierLabel => 'ハンドルまたはメール';

  @override
  String get identifierHint => 'user.bsky.social';

  @override
  String get passwordLabel => 'アプリパスワード';

  @override
  String get passwordHint => 'アプリパスワードを入力してください';

  @override
  String get identifierRequired => 'ハンドルまたはメールを入力してください';

  @override
  String get passwordRequired => 'アプリパスワードを入力してください';

  @override
  String get signInButton => 'サインイン';

  @override
  String get signingIn => 'サインイン中...';

  @override
  String get oAuthInDevelopment => 'OAuth開発中';

  @override
  String get addAccountButton => 'アカウントを追加';

  @override
  String get aboutAppPassword => 'アプリパスワードについて';

  @override
  String get appPasswordDescription =>
      'アプリパスワードはアプリ専用の安全なパスワードです。通常のパスワードより安全です。';

  @override
  String get generateAppPassword => 'アプリパスワードを生成 →';

  @override
  String get copyButton => 'コピー';

  @override
  String get loginError => 'サインインエラー';

  @override
  String get accountAddError => 'アカウント追加エラー';

  @override
  String get retryButton => '再試行';

  @override
  String get helpTextOAuth => 'OAuthは近日公開予定です。現在はアプリパスワードでサインインしてください。';

  @override
  String get helpTextAppPassword =>
      'アプリパスワードはBlueskyの設定で生成できます。通常のパスワードではなくアプリパスワードをご利用ください。';

  @override
  String get multiAccountInfo =>
      'moodeSkyは複数のBlueskyアカウントを同時に管理できます。新しいアカウントの認証情報を入力してください。';

  @override
  String get newAccountInfo => '新しいアカウントを追加';

  @override
  String get multiAccountHelpText => '複数のアカウントを同時に管理して、セッション期限を監視できます。';

  @override
  String get accountAddedSuccess => 'アカウントが正常に追加されました';

  @override
  String accountAddedSuccessWithName(String name) {
    return 'アカウント「$name」が追加されました';
  }

  @override
  String accountAddFailed(String error) {
    return 'アカウントの追加に失敗しました: $error';
  }

  @override
  String get accountAddCancelled => 'アカウントの追加がキャンセルされました';

  @override
  String get switchAccount => 'アカウント管理';

  @override
  String get signOutAll => 'すべてサインアウト';

  @override
  String get signOutAllConfirmTitle => 'すべてのアカウントからサインアウト';

  @override
  String get signOutAllConfirmMessage =>
      'すべてのアカウントからサインアウトしますか？再度サインインが必要になります。';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get signOutButton => 'サインアウト';

  @override
  String get loadingText => '読み込み中...';

  @override
  String get errorTitle => '問題が発生しました';

  @override
  String get languageLabel => '言語';

  @override
  String get languageDescription => 'アプリの言語を選択してください';

  @override
  String repostedBy(String name) {
    return '$nameがリポストしました';
  }

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get languageSettings => '言語設定';

  @override
  String get appearanceSettings => '外観設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get accountSettings => 'アカウント設定';

  @override
  String get manageAccounts => 'アカウント管理';

  @override
  String get manageAccountsDescription => 'アカウントの追加・削除';

  @override
  String get refreshProfiles => 'プロフィール更新';

  @override
  String get refreshProfilesDescription => 'すべてのアカウントのプロフィール情報とアバターを更新';

  @override
  String get refreshingProfiles => 'プロフィール情報を更新中...';

  @override
  String get profilesRefreshed => 'プロフィール情報が更新されました';

  @override
  String get refreshProfilesError => 'プロフィール更新に失敗しました';

  @override
  String get signOutAllDescription => 'すべてのアカウントからサインアウトしてログイン画面に戻る';

  @override
  String loginSuccess(String userName) {
    return 'ログイン成功: $userName';
  }

  @override
  String get close => '閉じる';

  @override
  String get appInformation => 'アプリ情報';

  @override
  String get aboutApp => 'moodeSkyについて';

  @override
  String appVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get aboutAppDescription =>
      'moodeSkyはデッキベースのインターフェースとマルチアカウント対応を備えたモダンなBlueskyクライアントです。';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get comingSoon => '近日公開';

  @override
  String get themeLabel => 'テーマ';

  @override
  String get themeDescription => 'アプリのテーマを選択してください';

  @override
  String get selectTheme => 'テーマを選択';

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLightDescription => '空の青をアクセントにした明るくクリーンなインターフェース';

  @override
  String get themeDarkDescription => '夕焼けのオレンジをアクセントにした快適なダークインターフェース';

  @override
  String get themeSystemDescription => 'システムのテーマ設定に自動的に従う';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get decksEmptyTitle => 'デッキがありません';

  @override
  String get decksEmptyDescription =>
      'ナビゲーションバーの「デッキ」ボタンから\nデッキを追加してタイムラインを表示しましょう';

  @override
  String get addDeckButton => 'デッキを追加';

  @override
  String get addDeckTooltip => 'デッキを追加';

  @override
  String get composeTooltip => '新しい投稿を作成';

  @override
  String get settingsTooltip => '設定画面を開く';

  @override
  String get homeNavigation => 'ホーム';

  @override
  String get notificationsNavigation => '通知';

  @override
  String get searchNavigation => '検索';

  @override
  String get profileNavigation => 'プロフィール';

  @override
  String get composeNavigation => '投稿';

  @override
  String get deckNavigation => 'デッキ';

  @override
  String get noLoggedInAccounts => 'ログイン中のアカウントがありません';

  @override
  String get notificationLike => 'あなたの投稿にいいねしました';

  @override
  String get notificationRepost => 'あなたの投稿をリポストしました';

  @override
  String get notificationFollow => 'あなたをフォローしました';

  @override
  String get notificationMention => 'あなたにメンションしました';

  @override
  String get notificationReply => 'あなたの投稿に返信しました';

  @override
  String get notification => '通知';

  @override
  String get followers => 'フォロワー';

  @override
  String get posts => '件の投稿';

  @override
  String get trending => 'トレンド';

  @override
  String get following => 'フォロー中';

  @override
  String get follow => 'フォロー';

  @override
  String get noProfileInfo => 'プロフィール情報はありません';

  @override
  String get sampleContent => 'サンプルコンテンツ';

  @override
  String hoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String get closeDeckFeature => 'デッキを閉じる機能は準備中です';

  @override
  String get composeFunctionUnderDev => '投稿作成機能は準備中です';

  @override
  String get notificationsFunctionUnderDev => '通知機能は準備中です';

  @override
  String get searchFunctionUnderDev => '検索機能は準備中です';

  @override
  String errorOccurred(String error) {
    return 'エラーが発生しました: $error';
  }

  @override
  String get deckTypeHome => 'ホーム';

  @override
  String get deckTypeNotifications => '通知';

  @override
  String get deckTypeSearch => '検索';

  @override
  String get deckTypeList => 'リスト';

  @override
  String get deckTypeProfile => 'プロフィール';

  @override
  String get deckTypeThread => 'スレッド';

  @override
  String get deckTypeCustomFeed => 'カスタムフィード';

  @override
  String get deckTypeLocal => 'ローカル';

  @override
  String get deckTypeHashtag => 'ハッシュタグ';

  @override
  String get deckTypeMentions => 'メンション';

  @override
  String get addDeckDialogTitle => 'デッキを追加';

  @override
  String get deckNameLabel => 'デッキ名';

  @override
  String get deckNameHint => '例: ホームタイムライン';

  @override
  String get deckTypeLabel => 'デッキタイプ';

  @override
  String get accountLabel => 'アカウント';

  @override
  String get useAllAccounts => 'すべてのアカウントで使用';

  @override
  String get addButton => '追加';

  @override
  String deckAddedSuccess(String deckName) {
    return 'デッキ「$deckName」を追加しました';
  }

  @override
  String deckAddFailed(String error) {
    return 'デッキの追加に失敗しました: $error';
  }

  @override
  String get timeNow => '今';

  @override
  String timeMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String timeHours(int hours) {
    return '$hours時間';
  }

  @override
  String timeDays(int days) {
    return '$days日';
  }

  @override
  String get numberThousandSuffix => 'K';

  @override
  String get numberMillionSuffix => 'M';

  @override
  String get multiAccount => 'マルチアカウント';

  @override
  String get deckOptions => 'デッキオプション';

  @override
  String get deckTypeCustom => 'カスタム';

  @override
  String get moveDeckLeft => '左に移動';

  @override
  String get moveDeckRight => '右に移動';

  @override
  String get deckSettings => 'デッキ設定';

  @override
  String get deleteDeck => 'デッキを削除';

  @override
  String get deckMovedLeft => 'デッキを左に移動しました';

  @override
  String get deckMovedRight => 'デッキを右に移動しました';

  @override
  String get deckMoveError => 'デッキの移動に失敗しました';

  @override
  String get deckSettingsComingSoon => 'デッキ設定機能は準備中です';

  @override
  String get deleteDeckTitle => 'デッキを削除';

  @override
  String deleteDeckConfirm(String deckTitle) {
    return '「$deckTitle」を削除しますか？この操作は取り消せません。';
  }

  @override
  String get deleteButton => '削除';

  @override
  String deckDeletedSuccess(String deckTitle) {
    return '「$deckTitle」を削除しました';
  }

  @override
  String get deckDeleteError => 'デッキの削除に失敗しました';

  @override
  String get richTextMentionLabel => 'メンション';

  @override
  String get richTextHashtagLabel => 'ハッシュタグ';

  @override
  String get richTextUrlLabel => 'URL';

  @override
  String richTextMentionTapped(String handle) {
    return 'メンション @$handle をタップしました';
  }

  @override
  String richTextHashtagTapped(String tag) {
    return 'ハッシュタグ #$tag をタップしました';
  }

  @override
  String richTextUrlTapped(String url) {
    return 'URL $url をタップしました';
  }

  @override
  String get richTextProfileView => 'プロフィールを表示';

  @override
  String get richTextHashtagSearch => 'ハッシュタグ検索';

  @override
  String get richTextOpenUrl => 'URLを開く';

  @override
  String get richTextCopyUrl => 'URLをコピー';

  @override
  String get richTextUrlCopied => 'URLをクリップボードにコピーしました';

  @override
  String get richTextUrlOpenFailed => 'URLを開けませんでした';

  @override
  String get richTextProcessingError => 'テキスト処理エラー';

  @override
  String get richTextFeatureNotImplemented => 'この機能は準備中です';

  @override
  String get loadingNewPosts => '最新のポストを取得しています...';

  @override
  String get loadingOlderPosts => '古いポストを取得しています...';
}
