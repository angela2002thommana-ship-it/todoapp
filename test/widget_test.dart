import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/app.dart';


void main() {
  testWidgets('a task can be added to the list', (tester) async {
    await tester.pumpWidget(const TodoApp());

    await tester.tap(find.text('Add a task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-title-input')),
      'Send the invoice',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('task-title-input')))
          .controller!
          .text,
      'Send the invoice',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Send the invoice'), findsOneWidget);
  });
}
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.



