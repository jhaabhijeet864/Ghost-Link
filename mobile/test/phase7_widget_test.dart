import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_loop/core/network/websocket_client.dart';
import 'package:local_loop/features/command/widgets/voice_dictation_modal.dart';
import 'package:local_loop/features/command/widgets/approval_detail_sheet.dart';
import 'package:local_loop/features/command/approval_inbox_screen.dart';
import 'package:local_loop/features/command/command_composer_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    WebSocketClient().disconnect();
  });

  group('Phase 7 Voice Dictation & Approval Tests', () {
    testWidgets('UI-08: VoiceDictationModal renders mic visualizer and confirms transcript', (WidgetTester tester) async {
      String? confirmedTranscript;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceDictationModal(
              onTranscriptConfirmed: (t) => confirmedTranscript = t,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Voice Command Dictation'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Use Transcript'), findsOneWidget);

      // Enter manual text in the transcript field
      await tester.enterText(find.byType(TextField), 'Deploy staging build');
      await tester.pump();

      // Tap Use Transcript
      await tester.tap(find.text('Use Transcript'));
      await tester.pumpAndSettle();

      expect(confirmedTranscript, 'Deploy staging build');
    });

    testWidgets('UI-08: CommandComposerScreen opens VoiceDictationModal when mic is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommandComposerScreen(
              deviceId: 'dev-1',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(find.byIcon(Icons.mic), findsOneWidget);

      // Tap mic icon
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Voice Command Dictation'), findsOneWidget);
      expect(find.text('Use Transcript'), findsOneWidget);

      WebSocketClient().disconnect();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('UI-09: ApprovalDetailSheet renders countdown timer, resources, and approves', (WidgetTester tester) async {
      final testItem = ApprovalItem(
        id: 'intent-101',
        action: 'delete_directory',
        target: 'C:/project/build',
        riskLevel: 'High',
        explanation: 'Removing build directory requires human authorization',
        timestamp: DateTime.now(),
        status: 'pending',
      );

      bool approved = false;
      bool rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApprovalDetailSheet(
              item: testItem,
              onApprove: () => approved = true,
              onReject: () => rejected = true,
              onExpired: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('delete_directory'), findsOneWidget);
      expect(find.text('Risk Level: High'), findsOneWidget);
      expect(find.text('C:/project/build'), findsOneWidget);
      expect(find.text('Removing build directory requires human authorization'), findsOneWidget);
      expect(find.text('Sign & Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      // Verify timer is displayed
      expect(find.textContaining('02:00'), findsOneWidget);

      // Tap Sign & Approve
      await tester.tap(find.text('Sign & Approve'));
      await tester.pumpAndSettle();

      expect(approved, isTrue);
      expect(rejected, isFalse);
    });

    testWidgets('UI-09: ApprovalDetailSheet handles expired state', (WidgetTester tester) async {
      final staleItem = ApprovalItem(
        id: 'intent-102',
        action: 'kill_process',
        target: 'PID: 9020',
        riskLevel: 'High',
        explanation: 'Process termination timed out',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'pending',
      );

      bool expiredCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApprovalDetailSheet(
              item: staleItem,
              onApprove: () {},
              onReject: () {},
              onExpired: () => expiredCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('EXPIRED'), findsOneWidget);
      expect(expiredCalled, isTrue);
    });
  });
}
