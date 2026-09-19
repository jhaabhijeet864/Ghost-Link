import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_loop/core/network/websocket_client.dart';
import 'package:local_loop/core/router/app_router.dart';
import 'package:local_loop/core/security/device_manager.dart';
import 'package:local_loop/features/workspaces/presentation/workspaces_dashboard_screen.dart';
import 'package:local_loop/features/workspaces/presentation/widgets/active_workstation_card.dart';
import 'package:local_loop/features/workspaces/presentation/widgets/manual_connect_dialog.dart';
import 'package:local_loop/features/settings/presentation/settings_screen.dart';

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

  group('Phase 5 Navigation & Workspaces Tests', () {
    testWidgets('UI-01: MainNavigationShell renders all 5 bottom destinations', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationShell(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      // Check all 5 tabs exist in NavigationBar
      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.text('Observe'), findsOneWidget);
      expect(find.text('Command'), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      
      WebSocketClient().disconnect();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('UI-01: Tapping tab changes active view without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationShell(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      // Tap Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings & Security'), findsOneWidget);
      expect(find.text('DEVICE CRYPTOGRAPHIC IDENTITY'), findsOneWidget);
      
      WebSocketClient().disconnect();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('UI-02: ActiveWorkstationCard displays machine info and actions', (WidgetTester tester) async {
      final testDevice = SavedDevice(
        id: 'test-id-1',
        name: 'PREADATOR-LocalLoop',
        ip: '127.0.0.1',
        port: '8080',
        machineName: 'PREADATOR-LocalLoop',
        lastConnected: DateTime.now(),
      );

      bool reconnected = false;
      bool switched = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveWorkstationCard(
              activeDevice: testDevice,
              onDisconnect: () {},
              onReconnect: () => reconnected = true,
              onSwitch: () => switched = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PREADATOR-LocalLoop'), findsOneWidget);
      expect(find.text('127.0.0.1:8080'), findsOneWidget);
      expect(find.text('Ed25519 Signed'), findsOneWidget);
      expect(find.text('Reconnect'), findsOneWidget);
      expect(find.text('Switch Host'), findsOneWidget);

      await tester.tap(find.text('Reconnect'));
      expect(reconnected, isTrue);

      await tester.tap(find.text('Switch Host'));
      expect(switched, isTrue);
    });

    testWidgets('UI-03: WorkspacesDashboardScreen displays title and pair button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkspacesDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LocalLoop'), findsOneWidget);
      expect(find.byIcon(Icons.add_link), findsOneWidget);
    });

    testWidgets('UI-04: ManualConnectDialog validates IP and port and connects', (WidgetTester tester) async {
      String? connectedIp;
      String? connectedPort;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualConnectDialog(
              onConnect: (ip, port, token) {
                connectedIp = ip;
                connectedPort = port;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual Connection'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Tap Quick Connect
      await tester.tap(find.text('Quick Connect: 127.0.0.1:8080'));
      await tester.pumpAndSettle();

      expect(connectedIp, '127.0.0.1');
      expect(connectedPort, '8080');
    });

    testWidgets('UI-10: SettingsScreen displays cryptographic identity card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Security'), findsOneWidget);
      expect(find.text('DEVICE CRYPTOGRAPHIC IDENTITY'), findsOneWidget);
      expect(find.text('COMMAND & APPROVAL POLICIES'), findsOneWidget);
      expect(find.text('PAIRINGS MANAGEMENT'), findsOneWidget);
      expect(find.text('Revoke All Pairings'), findsOneWidget);
    });
  });
}
