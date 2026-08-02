// Basic smoke test: confirms the app boots and shows the login screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:idea/app.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ScamLockApp());

    expect(find.text('ScamLock'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}