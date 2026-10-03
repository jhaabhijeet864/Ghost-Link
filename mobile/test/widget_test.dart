import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_loop/main.dart';

void main() {
  testWidgets('LocalLoopApp renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LocalLoopApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
