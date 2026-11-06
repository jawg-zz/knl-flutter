import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knlapp/main.dart';

void main() {
  testWidgets('KNL app boots to Home', (tester) async {
    await tester.pumpWidget(const KnlApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Kisii Newlife SDA'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Songs'), findsAtLeastNWidgets(1));
  });
}
