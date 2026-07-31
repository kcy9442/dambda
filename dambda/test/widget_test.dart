import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dambda/main.dart';

void main() {
  testWidgets('Home feed shows DAMBDA title and product list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DambdaApp());

    expect(find.text('DAMBDA'), findsOneWidget);
    expect(find.text('딜라이트 프로젝트 과일칩 모음전'), findsOneWidget);

    await tester.tap(find.text('딜라이트 프로젝트 과일칩 모음전'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Delight Project Fruit Chips Set'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsWidgets);
  });
}
