// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:moodesky/core/theme/app_fonts.dart';

/// MoodeSkyアプリのテーマ定義
class AppThemes {
  /// 空をイメージした爽やかな青（ライトテーマ用）
  static const Color skyBlue = Color(0xFF2196F3); // Material Blue 500
  static const Color skyBlueLight = Color(0xFF64B5F6); // Material Blue 400
  static const Color skyBlueDark = Color(0xFF1976D2); // Material Blue 700

  /// 夕焼けをイメージしたオレンジ（ダークテーマ用）
  static const Color sunsetOrange = Color(
    0xFFFF7043,
  ); // Material Deep Orange 400
  static const Color sunsetOrangeLight = Color(
    0xFFFF8A65,
  ); // Material Deep Orange 300
  static const Color sunsetOrangeDark = Color(
    0xFFFF5722,
  ); // Material Deep Orange 500

  /// 自然をイメージした緑（セカンダリ用）
  static const Color forestGreen = Color(0xFF4CAF50); // Material Green 500
  static const Color oceanTeal = Color(0xFF26A69A); // Material Teal 400
  static const Color lavenderPurple = Color(0xFF9C27B0); // Material Purple 500
  static const Color sunflowerYellow = Color(0xFFFFC107); // Material Amber 500

  /// アクション用カラー
  static const Color repostGreen = Color(0xFF34C759); // iOS-style Green
  static const Color likeRed = Color(0xFFFF2D55); // iOS-style Pink/Red

  /// プレミアムな影の定義
  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// ガラス効果の背景（透過）
  static Color getGlassColor(BuildContext context, {double opacity = 0.7}) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: opacity)
        : const Color(0xFF1E1E1E).withValues(alpha: opacity);
  }

  /// ライトテーマ - 空の青をアクセントに
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // テキストテーマ - 視認性向上のためフォントウェイトを1段階上げて調整
    textTheme: const TextTheme(
      // Display styles (w400 → w500)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        color: Color(0xFF1A1A1A),
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
      ),

      // Headline styles (w500 → w600)
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),

      // Title styles (w600 → w700)
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        color: Color(0xFF1A1A1A),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: Color(0xFF1A1A1A),
      ),

      // Body styles - 視認性向上のためフォントウェイトを1段階上げて調整 (w400 → w500)
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.6,
        color: Color(0xFF1A1A1A),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
        height: 1.5,
        color: Color(0xFF2A2A2A),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
        color: Color(0xFF424242),
      ),

      // Label styles (w500 → w600)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: Color(0xFF1A1A1A),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF2A2A2A),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF424242),
      ),
    ),

    // カラースキーム
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: skyBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF007AFF), // Apple Blue
          primaryContainer: const Color(0xFFE5F1FF),
          onPrimaryContainer: const Color(0xFF004080),
          secondary: const Color(0xFF5856D6), // Apple Purple
          tertiary: const Color(0xFF32ADE6), // Apple Cyan
          surface: Colors.white,
          surfaceContainer: const Color(0xFFF2F2F7), // iOS System Gray 6
          surfaceContainerHighest: const Color(0xFFE5E5EA), // iOS System Gray 5
          onSurface: const Color(0xFF1C1C1E),
          onSurfaceVariant: const Color(0xFF3A3A3C),
          outline: const Color(0xFFC7C7CC),
          outlineVariant: const Color(0xFFE5E5EA),
          shadow: Colors.black.withValues(alpha: 0.1),
        ),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1A1A1A),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // カード
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),

    // リストタイル - 視認性向上のためテキストスタイルを調整
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      horizontalTitleGap: 16,
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      subtitleTextStyle: TextStyle(
        color: Color(0xFF333333),
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
    ),

    // 区切り線
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 0.5,
      space: 1,
    ),

    // インプットフィールド
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: skyBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // スナックバー
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  /// ダークテーマ - 夕焼けのオレンジをアクセントに
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // テキストテーマ - 視認性向上のためフォントウェイトを1段階上げて調整
    textTheme: const TextTheme(
      // Display styles (w400 → w500)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        color: Color(0xFFF5F5F5),
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF5F5F5),
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF5F5F5),
      ),

      // Headline styles (w500 → w600)
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F5),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F5),
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F5),
      ),

      // Title styles (w600 → w700)
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF5F5F5),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        color: Color(0xFFF5F5F5),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: Color(0xFFF5F5F5),
      ),

      // Body styles - 視認性向上のためフォントウェイトを1段階上げて調整 (w400 → w500)
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.6,
        color: Color(0xFFF5F5F5),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
        height: 1.5,
        color: Color(0xFFE0E0E0),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
        color: Color(0xFFBDBDBD),
      ),

      // Label styles (w500 → w600)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: Color(0xFFF5F5F5),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFFE0E0E0),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFFBDBDBD),
      ),
    ),

    // カラースキーム
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: sunsetOrange,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFFF9F0A), // Apple Orange (Dark)
          primaryContainer: const Color(0xFF3D2400),
          onPrimaryContainer: const Color(0xFFFFD60A),
          secondary: const Color(0xFFBF5AF2), // Apple Purple (Dark)
          tertiary: const Color(0xFF64D2FF), // Apple Cyan (Dark)
          surface: const Color(0xFF1C1C1E), // iOS Dark Gray 6
          surfaceContainer: const Color(0xFF2C2C2E), // iOS Dark Gray 5
          surfaceContainerHighest: const Color(0xFF3A3A3C), // iOS Dark Gray 4
          onSurface: const Color(0xFFF2F2F7),
          onSurfaceVariant: const Color(0xFFAEAEB2),
          outline: const Color(0xFF48484A),
          outlineVariant: const Color(0xFF3A3A3C),
          shadow: Colors.black.withValues(alpha: 0.3),
        ),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFE0E0E0),
      titleTextStyle: TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // カード
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Color(0xFF3D3D3D), width: 1),
      ),
    ),

    // リストタイル - 視認性向上のためテキストスタイルを調整
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      horizontalTitleGap: 16,
      titleTextStyle: TextStyle(
        color: Color(0xFFF5F5F5),
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      subtitleTextStyle: TextStyle(
        color: Color(0xFFCCCCCC),
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
    ),

    // 区切り線
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3D3D3D),
      thickness: 0.5,
      space: 1,
    ),

    // インプットフィールド
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: sunsetOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // スナックバー
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2D2D2D),
      contentTextStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  /// ライトテーマ用のシステムUIオーバーレイスタイル
  static const SystemUiOverlayStyle lightSystemUiOverlayStyle =
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Color(0xFFE0E0E0),
      );

  /// ダークテーマ用のシステムUIオーバーレイスタイル
  static const SystemUiOverlayStyle darkSystemUiOverlayStyle =
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFF121212),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF121212),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Color(0xFF3D3D3D),
      );

  /// アプリのカラースキームを取得
  static AppColorScheme getColorScheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    
    return AppColorScheme(
      primary: brightness == Brightness.light ? skyBlue : sunsetOrange,
      secondary: brightness == Brightness.light ? skyBlueLight : sunsetOrangeLight,
      surface: colorScheme.surface,
      background: colorScheme.surface,
      error: colorScheme.error,
      onPrimary: colorScheme.onPrimary,
      onSecondary: colorScheme.onSecondary,
      onSurface: colorScheme.onSurface,
      onBackground: colorScheme.onSurface,
      onError: colorScheme.onError,
      info: brightness == Brightness.light ? skyBlue : sunsetOrange,
      infoWithOpacity: brightness == Brightness.light 
          ? skyBlue.withValues(alpha: 0.1) 
          : sunsetOrange.withValues(alpha: 0.1),
    );
  }

  /// アプリのテキストスタイルを取得
  static AppTextStyles getTextStyles(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return AppTextStyles(
      headlineLarge: textTheme.headlineLarge!,
      headlineMedium: textTheme.headlineMedium!,
      headlineSmall: textTheme.headlineSmall!,
      titleLarge: textTheme.titleLarge!,
      titleMedium: textTheme.titleMedium!,
      titleSmall: textTheme.titleSmall!,
      bodyLarge: textTheme.bodyLarge!,
      bodyMedium: textTheme.bodyMedium!,
      bodySmall: textTheme.bodySmall!,
      labelLarge: textTheme.labelLarge!,
      labelMedium: textTheme.labelMedium!,
      labelSmall: textTheme.labelSmall!,
    );
  }

  /// 現在のテーマに基づいてシステムUIオーバーレイスタイルを取得
  static SystemUiOverlayStyle getSystemUiOverlayStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: brightness,
      statusBarIconBrightness: brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
      systemNavigationBarColor: colorScheme.surface,
      systemNavigationBarIconBrightness: brightness == Brightness.light
          ? Brightness.dark
          : Brightness.light,
    );
  }

  /// システムUIオーバーレイスタイルを適用
  static void setSystemUiOverlayStyle(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(getSystemUiOverlayStyle(context));
  }

}

/// アプリカラースキーム
class AppColorScheme {
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color onError;
  final Color info;
  final Color infoWithOpacity;

  const AppColorScheme({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.info,
    required this.infoWithOpacity,
  });
}

/// アプリテキストスタイル
class AppTextStyles {
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  // 下位互換性のためのcaptionプロパティ
  TextStyle get caption => labelSmall;

  const AppTextStyles({
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });
}

/// ポストアイテム用のスタイル
class PostItemStyle {
  final BuildContext context;

  const PostItemStyle(this.context);

  /// ポストアイテムの装飾（上下線のみ）
  BoxDecoration getPostDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
    );
  }

  /// ポストアイテムの内側パディング
  static const EdgeInsets postPadding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 16,
  );

  /// ポストアイテム間のマージン (左右の余白)
  static const EdgeInsets postMargin = EdgeInsets.symmetric(horizontal: 6.0);

  /// ポストの区切り線用Widget
  Widget buildPostDivider() {
    return Container(
      height: 0.5,
      color: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFE0E0E0)
          : const Color(0xFF424242),
    );
  }

  /// ポストアイテムのContainer（下ボーダーのみ統一）
  Widget buildPostContainer({
    required Widget child,
    bool showTopBorder = false, // 非推奨：後方互換のため残す
    bool showBottomBorder = true, // 常に下ボーダーを表示
  }) {
    return Container(
      width: double.infinity,
      padding: postPadding,
      margin: postMargin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          // 上ボーダーは廃止（重複による太線を防ぐ）
          bottom: showBottomBorder
              ? BorderSide(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF424242),
                  width: 0.5,
                )
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }

  // 静的なファクトリーメソッドを後方互換性のために残す
  static Widget buildPostContainerStatic({
    required BuildContext context,
    required Widget child,
    bool showTopBorder = false, // 非推奨：後方互換のため残す
    bool showBottomBorder = true, // 常に下ボーダーを表示
  }) {
    return PostItemStyle(context).buildPostContainer(
      child: child,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
    );
  }
}

/// アクション用カラーのエクステンション
extension AppActionColors on ColorScheme {
  /// リポスト用の緑色
  Color get repostColor => AppThemes.repostGreen;

  /// いいね用の赤色
  Color get likeColor => AppThemes.likeRed;
}

/// BlueskyRichText用のテーマ色拡張
extension BlueskyTextColors on ColorScheme {
  /// メンション（@username）のカラー - プライマリーカラーを使用
  /// ライトテーマ: 空の青 #2196F3, ダークテーマ: 夕焼けオレンジ #FF7043
  Color get mentionColor => primary;

  /// ハッシュタグ（#hashtag）のカラー - プライマリーカラーを使用（統一性のため）
  /// ライトテーマ: 空の青 #2196F3, ダークテーマ: 夕焼けオレンジ #FF7043
  Color get hashtagColor => primary;

  /// URL（https://...）のカラー - プライマリーカラーを使用（統一性のため）
  /// ライトテーマ: 空の青 #2196F3, ダークテーマ: 夕焼けオレンジ #FF7043
  Color get urlColor => primary;

  /// メンションのホバー/アクティブ状態のカラー
  Color get mentionActiveColor => primaryContainer;

  /// ハッシュタグのホバー/アクティブ状態のカラー
  Color get hashtagActiveColor => primaryContainer;

  /// URLのホバー/アクティブ状態のカラー
  Color get urlActiveColor => primaryContainer;

  /// 高コントラスト版のメンションカラー（可読性重視）
  Color get mentionColorHighContrast => brightness == Brightness.light
      ? const Color(0xFF1565C0) // より濃い青
      : const Color(0xFFFF8A65); // より明るいオレンジ

  /// 高コントラスト版のハッシュタグカラー（可読性重視）
  Color get hashtagColorHighContrast => brightness == Brightness.light
      ? const Color(0xFF1565C0) // より濃い青（統一）
      : const Color(0xFFFF8A65); // より明るいオレンジ（統一）

  /// 高コントラスト版のURLカラー（可読性重視）
  Color get urlColorHighContrast => brightness == Brightness.light
      ? const Color(0xFF1565C0) // より濃い青（統一）
      : const Color(0xFFFF8A65); // より明るいオレンジ（統一）
}

/// 危険なアクション（サインアウト・削除）用のカラー拡張
extension DangerousActionColors on ColorScheme {
  /// 強化されたエラーカラー（サインアウト・削除用）
  /// ライトテーマ: より強い赤 #D32F2F, ダークテーマ: より明るい赤 #FF5252
  Color get strongErrorColor => brightness == Brightness.light
      ? const Color(0xFFD32F2F) // Material Red 700
      : const Color(0xFFFF5252); // Material Red 400
}

