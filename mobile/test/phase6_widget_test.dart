import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_loop/features/observe/presentation/widgets/code_diff_viewer.dart';
import 'package:local_loop/features/observe/presentation/widgets/screenshot_previewer.dart';
import 'package:local_loop/features/observe/presentation/observe_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CodeDiffViewer Widget Tests', () {
    testWidgets('renders file path and additions/deletions badges', (WidgetTester tester) async {
      const diff = '@@ -1,3 +1,4 @@\n- old line\n+ new line 1\n+ new line 2';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CodeDiffViewer(
              filePath: 'src/Worker.cs',
              diffContent: diff,
            ),
          ),
        ),
      );

      expect(find.text('src/Worker.cs'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
      expect(find.textContaining('new line 1'), findsOneWidget);
      expect(find.textContaining('old line'), findsOneWidget);
    });

    testWidgets('toggles collapse/expand when header is tapped', (WidgetTester tester) async {
      const diff = '+ addition line';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CodeDiffViewer(
              filePath: 'src/Worker.cs',
              diffContent: diff,
            ),
          ),
        ),
      );

      expect(find.textContaining('addition line'), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.text('src/Worker.cs'));
      await tester.pump();

      expect(find.textContaining('addition line'), findsNothing);
    });
  });

  group('ScreenshotPreviewer Widget Tests', () {
    testWidgets('shows placeholder when no screenshot available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenshotPreviewer(
              lastScreenshotBase64: null,
              onRequestScreenshot: () {},
            ),
          ),
        ),
      );

      expect(find.text('Host Display Capture'), findsOneWidget);
      expect(find.text('No Screenshot Captured Yet'), findsOneWidget);
      expect(find.text('Capture Fresh'), findsOneWidget);
    });

    testWidgets('triggers callback when Capture Fresh button tapped', (WidgetTester tester) async {
      bool triggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenshotPreviewer(
              lastScreenshotBase64: null,
              onRequestScreenshot: () {
                triggered = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Capture Fresh'));
      await tester.pump();

      expect(triggered, isTrue);
    });
  });

  group('ObserveScreen Tests', () {
    testWidgets('shows filter category chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ObserveScreen(),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Agent Logs'), findsOneWidget);
      expect(find.text('Diffs'), findsOneWidget);
      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('Errors'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
