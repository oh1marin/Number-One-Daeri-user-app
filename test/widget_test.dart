import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:number_one_daeri_user_app/main.dart';

void main() {
  testWidgets('MyApp loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
