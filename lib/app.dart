import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/todo_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/todo_screen.dart';
import 'services/auth_service.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Todo List',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        initialData: AuthService.instance.currentUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;

          if (user == null) {
            return const AuthScreen();
          }

          return ChangeNotifierProvider(
            key: ValueKey(user.uid),
            create: (_) => TodoProvider(userId: user.uid)..loadTodos(),
            child: const TodoScreen(),
          );
        },
      ),
    );
  }
}
