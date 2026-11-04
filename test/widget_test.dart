import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/providers/todo_provider.dart';
import 'package:todoapp/screens/todo_screen.dart';

void main() {
  testWidgets('a task can be added to the list', (tester) async {
    final provider = TodoProvider.forTesting(userId: 'test-user');

    await tester.pumpWidget(
      ChangeNotifierProvider<TodoProvider>.value(
        value: provider,
        child: const MaterialApp(home: TodoScreen(enableVideo: false)),
      ),
    );

    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final titleField = find.byKey(const ValueKey('task-title-input'));

    expect(titleField, findsOneWidget);

    await tester.enterText(titleField, 'Send the invoice');

    expect(
      tester.widget<TextField>(titleField).controller!.text,
      'Send the invoice',
    );

    final addTaskButton = find.widgetWithText(ElevatedButton, 'Add Task');

    await tester.ensureVisible(addTaskButton);
    await tester.tap(addTaskButton);
    await tester.pumpAndSettle();

    expect(find.text('Send the invoice'), findsOneWidget);

    provider.dispose();
  });
}
