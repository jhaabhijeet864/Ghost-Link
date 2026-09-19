import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_loop/core/security/device_manager.dart';
import 'package:local_loop/features/settings/presentation/settings_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Phase 8 Settings & Security Tests', () {
    testWidgets('UI-10: Displays device identity card and Ed25519 key info', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Security'), findsOneWidget);
      expect(find.text('DEVICE CRYPTOGRAPHIC IDENTITY'), findsOneWidget);
      expect(find.text('Ed25519 Signing Key'), findsOneWidget);
      expect(find.text('Curve25519 • Hardware/Secure Keystore'), findsOneWidget);
      expect(find.text('Key Fingerprint:'), findsOneWidget);
    });

    testWidgets('UI-11: Displays security and risk policy rows', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMMAND & APPROVAL POLICIES'), findsOneWidget);
      expect(find.text('Telemetry & Logs (Read)'), findsOneWidget);
      expect(find.text('Auto-allowed'), findsOneWidget);
      expect(find.text('File Modifications'), findsOneWidget);
      expect(find.text('Terminal & Shell Commands'), findsOneWidget);
      expect(find.text('Replay Attack Window'), findsOneWidget);
      expect(find.text('30 Seconds (Max)'), findsOneWidget);
    });

    testWidgets('UI-12: Revoke All Pairings opens dialog and executes reset', (WidgetTester tester) async {
      final deviceManager = DeviceManager();
      await deviceManager.saveDevice(SavedDevice(
        id: 'dev-1',
        name: 'Work Laptop',
        ip: '192.168.1.50',
        port: '8080',
      ));

      expect((await deviceManager.getSavedDevices()).length, 1);

      int? navigatedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            onNavigateTab: (index) => navigatedIndex = index,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to and tap Revoke All Pairings
      await tester.ensureVisible(find.text('Revoke All Pairings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke All Pairings'));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.text('Revoke All Pairings?'), findsOneWidget);
      expect(find.text('This will remove all saved workstation pairings, disconnect active sessions, and require re-scanning the QR code to pair again.'), findsOneWidget);

      // Tap confirmation
      await tester.tap(find.text('Revoke All'));
      await tester.pumpAndSettle();

      // Verify devices wiped
      expect((await deviceManager.getSavedDevices()).length, 0);
      expect(navigatedIndex, 0); // Redirected to Workspaces tab
    });
  });
}
