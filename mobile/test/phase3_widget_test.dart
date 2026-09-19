import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_loop/features/command/command_composer_screen.dart';
import 'package:local_loop/features/command/approval_inbox_screen.dart';
import 'package:local_loop/core/network/websocket_client.dart';

@GenerateMocks([WebSocketClient])
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CommandComposerScreen Tests', () {
    testWidgets('shows connection status indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommandComposerScreen(
              deviceId: 'test-device',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.text('Command Composer'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('shows quick action chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommandComposerScreen(
              deviceId: 'test-device',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.text('Read Logs'), findsOneWidget);
      expect(find.text('Check Status'), findsOneWidget);
      expect(find.text('Restart Service'), findsOneWidget);
      expect(find.text('View Processes'), findsOneWidget);
      expect(find.text('Kill Process'), findsOneWidget);
      expect(find.text('Run Build'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('shows custom command input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommandComposerScreen(
              deviceId: 'test-device',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a command (e.g., "Restart the web server")...'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('shows risk level guide', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommandComposerScreen(
              deviceId: 'test-device',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.text('Risk Level Guide'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('ApprovalInboxScreen Tests', () {
    testWidgets('shows empty state when no pending approvals', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ApprovalInboxScreen(
              deviceId: 'test-device',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.text('Approval Inbox'), findsOneWidget);
      expect(find.text('No Pending Approvals'), findsOneWidget);
      expect(find.text('You have no actions waiting for your review.'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('shows connection status indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ApprovalInboxScreen(
              deviceId: 'test-device',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('shows history button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ApprovalInboxScreen(
              deviceId: 'test-device',
              ip: '127.0.0.1',
              port: '8080',
              token: 'test-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.idle();

      expect(find.byIcon(Icons.history), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('QuickAction Risk Levels', () {
    test('Low risk actions have green color', () {
      const action = QuickAction(
        label: 'Read Logs',
        icon: Icons.article,
        command: 'read logs',
        riskLevel: 'Low',
      );
      expect(action.riskColor, equals(Colors.green));
    });

    test('Medium risk actions have orange color', () {
      const action = QuickAction(
        label: 'Restart Service',
        icon: Icons.restart_alt,
        command: 'restart service',
        riskLevel: 'Medium',
      );
      expect(action.riskColor, equals(Colors.orange));
    });

    test('High risk actions have red color', () {
      const action = QuickAction(
        label: 'Kill Process',
        icon: Icons.stop_circle,
        command: 'kill process',
        riskLevel: 'High',
      );
      expect(action.riskColor, equals(Colors.red));
    });
  });

  group('ApprovalItem Risk Levels', () {
    test('Low risk approval item has green color', () {
      final item = ApprovalItem(
        id: '1',
        action: 'read',
        target: 'logs',
        riskLevel: 'Low',
        explanation: 'Read logs',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        status: 'pending',
      );
      expect(item.riskColor, equals(const Color(0xFF00E676)));
      expect(item.riskIcon, equals(Icons.check_circle));
    });

    test('Medium risk approval item has orange color', () {
      final item = ApprovalItem(
        id: '1',
        action: 'restart',
        target: 'service',
        riskLevel: 'Medium',
        explanation: 'Restart service',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        status: 'pending',
      );
      expect(item.riskColor, equals(const Color(0xFFFFB300)));
      expect(item.riskIcon, equals(Icons.warning));
    });

    test('High risk approval item has red color', () {
      final item = ApprovalItem(
        id: '1',
        action: 'delete',
        target: 'file',
        riskLevel: 'High',
        explanation: 'Delete file',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        status: 'pending',
      );
      expect(item.riskColor, equals(const Color(0xFFFF3D00)));
      expect(item.riskIcon, equals(Icons.dangerous));
    });
  });
}