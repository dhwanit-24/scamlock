import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:idea/core/routes/app_routes.dart';
import 'package:idea/features/support/presentation/widgets/support_fab.dart';

void main() {
  testWidgets('Help confirmation opens the support route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.contactSupport: (_) =>
          const Scaffold(body: Text('Support page')),
        },
        home: const Scaffold(floatingActionButton: SupportFab()),
      ),
    );

    await tester.tap(find.byTooltip('Get help'));
    await tester.pumpAndSettle();
    expect(find.text('Need help?'), findsOneWidget);

    await tester.tap(find.text('Yes, contact developer'));
    await tester.pumpAndSettle();
    expect(find.text('Support page'), findsOneWidget);
  });
}