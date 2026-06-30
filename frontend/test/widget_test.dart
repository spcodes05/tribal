// Basic smoke test for TRIBAL.
//
// Confirms the app boots without throwing. This replaces the default
// Flutter counter-app template test (which referenced a nonexistent
// `MyApp` class) — TRIBAL's actual root widget is `TribalApp`, defined
// in lib/main.dart, and there's no counter screen in this app at all.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('TribalApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const TribalApp());

    // Let the initial route (onboarding) settle.
    await tester.pumpAndSettle();

    // A MaterialApp.router should be in the tree, confirming GoRouter
    // initialized and rendered some screen without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
