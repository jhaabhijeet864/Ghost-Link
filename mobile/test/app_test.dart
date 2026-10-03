import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_loop/main.dart';

void main() {
  testWidgets('End-to-End UI Verification (Smoke Test)', (WidgetTester tester) async {
    // Start the app
    await tester.pumpWidget(const ProviderScope(child: LocalLoopApp()));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify root MaterialApp and LocalLoop header renders
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('LocalLoop'), findsWidgets);

    // Verify navigation tabs exist
    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('Sessions'), findsWidgets);
    expect(find.text('Machines'), findsWidgets);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Tap on Sessions tab
    await tester.tap(find.text('Sessions'));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on Projects tab
    await tester.tap(find.text('Projects'));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
