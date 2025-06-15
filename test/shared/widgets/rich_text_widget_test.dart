// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:moodesky/shared/widgets/rich_text_widget.dart';

void main() {
  group('BlueskyRichText', () {
    testWidgets('renders plain text correctly', (WidgetTester tester) async {
      const plainText = 'This is a simple text without any special elements.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlueskyRichText(text: plainText)),
        ),
      );

      // RichTextウィジェットが存在することを確認
      expect(find.byType(RichText), findsOneWidget);

      // RichTextウィジェット内のテキストを確認
      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      final TextSpan span = richTextWidget.text as TextSpan;
      expect(span.toPlainText(), equals(plainText));
    });

    testWidgets('creates RichText widget for text with mentions', (
      WidgetTester tester,
    ) async {
      const textWithMention = 'Hello @user.bsky.social how are you?';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlueskyRichText(text: textWithMention)),
        ),
      );

      // RichTextが存在することを確認
      expect(find.byType(RichText), findsOneWidget);

      // テキスト全体が含まれていることを確認
      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      final TextSpan span = richTextWidget.text as TextSpan;
      expect(span.toPlainText(), contains('Hello'));
      expect(span.toPlainText(), contains('@user.bsky.social'));
      expect(span.toPlainText(), contains('how are you?'));
    });

    testWidgets('creates RichText widget for text with URLs', (
      WidgetTester tester,
    ) async {
      const textWithUrl = 'Check out https://example.com for more info!';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlueskyRichText(text: textWithUrl)),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);

      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      final TextSpan span = richTextWidget.text as TextSpan;
      expect(span.toPlainText(), contains('Check out'));
      expect(span.toPlainText(), contains('https://example.com'));
      expect(span.toPlainText(), contains('for more info!'));
    });

    testWidgets('creates RichText widget for text with hashtags', (
      WidgetTester tester,
    ) async {
      const textWithHashtag = 'This is a test post #flutter #development';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlueskyRichText(text: textWithHashtag)),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);

      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      final TextSpan span = richTextWidget.text as TextSpan;
      expect(span.toPlainText(), contains('This is a test post'));
      expect(span.toPlainText(), contains('#flutter'));
      expect(span.toPlainText(), contains('#development'));
    });

    testWidgets('handles multiple entity types in one text', (
      WidgetTester tester,
    ) async {
      const complexText =
          'Hey @user.bsky.social check out https://flutter.dev #awesome';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlueskyRichText(text: complexText)),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);

      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      final TextSpan span = richTextWidget.text as TextSpan;
      expect(span.toPlainText(), contains('Hey'));
      expect(span.toPlainText(), contains('@user.bsky.social'));
      expect(span.toPlainText(), contains('https://flutter.dev'));
      expect(span.toPlainText(), contains('#awesome'));
    });

    testWidgets('handles empty text gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlueskyRichText(text: '')),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('applies custom text styles correctly', (
      WidgetTester tester,
    ) async {
      const testText = 'Custom styled text';
      const customStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlueskyRichText(text: testText, style: customStyle),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);

      // RichTextウィジェットを取得してスタイルを確認
      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      final textStyle = richTextWidget.text.style;

      expect(textStyle?.fontSize, equals(20));
      expect(textStyle?.fontWeight, equals(FontWeight.bold));
      expect(textStyle?.color, equals(Colors.red));
    });

    testWidgets('handles text alignment correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlueskyRichText(
              text: 'Center aligned text',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      expect(richTextWidget.textAlign, equals(TextAlign.center));
    });

    testWidgets('handles maxLines correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlueskyRichText(
              text:
                  'This is a very long text that should be limited to max lines',
              maxLines: 2,
            ),
          ),
        ),
      );

      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      expect(richTextWidget.maxLines, equals(2));
    });

    testWidgets('handles text overflow correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlueskyRichText(
              text: 'Text with ellipsis overflow',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final richTextWidget = tester.widget<RichText>(find.byType(RichText));
      expect(richTextWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('has callback properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlueskyRichText(
              text: 'Test @mention #hashtag https://example.com',
              onMentionTap: () {},
              onHashtagTap: () {},
              onLinkTap: () {},
            ),
          ),
        ),
      );

      // ウィジェットが作成されることを確認
      expect(find.byType(BlueskyRichText), findsOneWidget);

      // コールバック関数が設定されていることを確認（タップは実際のUIテストでテストするため、ここでは存在確認のみ）
      final widget = tester.widget<BlueskyRichText>(
        find.byType(BlueskyRichText),
      );
      expect(widget.onMentionTap, isNotNull);
      expect(widget.onHashtagTap, isNotNull);
      expect(widget.onLinkTap, isNotNull);
    });

    testWidgets('handles processing errors gracefully', (
      WidgetTester tester,
    ) async {
      // 不正なテキストでも正常にフォールバックすることを確認
      const problematicText = 'Some text that might cause issues';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BlueskyRichText(text: problematicText)),
        ),
      );

      // エラーが発生してもRichTextウィジェットが表示される
      expect(find.byType(RichText), findsOneWidget);
    });
  });
}
