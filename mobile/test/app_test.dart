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
    expect(find.text('Inbox'), findsWidgets);

    expect(find.text('Workspaces'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Tap on Workspaces tab
    await tester.tap(find.text('Workspaces'));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
