import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_loop/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('End-to-End UI Verification (Smoke Test)', (WidgetTester tester) async {
    // Start the app
    await tester.pumpWidget(const ProviderScope(child: LocalLoopApp()));
    await tester.pumpAndSettle();

    // Verify we start on the HomeScreen with Machines tab
    expect(find.text('Machines'), findsWidgets);
    
    // Tap on Workspaces tab in BottomNavigationBar
    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Workspaces Dashboard'), findsWidgets);

    // Tap on Sessions tab
    await tester.tap(find.byIcon(Icons.terminal_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Sessions'), findsWidgets);
    
    // Navigate back to machines to verify pairing button exists
    await tester.tap(find.byIcon(Icons.computer));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsWidgets); // Pairing button
  });
}
