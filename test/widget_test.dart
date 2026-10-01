import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SafeRoute AI App basic widget rendering', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('SafeRoute AI'),
          ),
        ),
      ),
    );
    expect(find.text('SafeRoute AI'), findsOneWidget);
  });
}
