import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/todo.dart';

class FirestoreTodoService {
  FirestoreTodoService._();

  static final FirestoreTodoService instance = FirestoreTodoService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _todosCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('todos');
  }

  String _documentIdFor(Todo todo) {
    var titleSlug = todo.title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (titleSlug.isEmpty) {
      titleSlug = 'task';
    }

    if (titleSlug.length > 80) {
      titleSlug = titleSlug.substring(0, 80);
      titleSlug = titleSlug.replaceAll(RegExp(r'-+$'), '');
    }

    final uniqueSuffix = base64Url
        .encode(utf8.encode(todo.id))
        .replaceAll('=', '');

    return '$titleSlug--$uniqueSuffix';
  }

  Future<List<Todo>> loadTodos(String uid) async {
    final snapshot = await _todosCollection(uid).get();

    return snapshot.docs.map((document) {
      final data = document.data();

      return Todo.fromJson({...data, 'id': data['id'] ?? document.id});
    }).toList();
  }

  Future<void> saveTodo(String uid, Todo todo) async {
    final collection = _todosCollection(uid);
    final snapshot = await collection.get();
    final newDocumentId = _documentIdFor(todo);
    final batch = _firestore.batch();

    var operationCount = 1;

    for (final document in snapshot.docs) {
      final data = document.data();
      final storedTodoId = data['id'] ?? document.id;

      if (storedTodoId == todo.id && document.id != newDocumentId) {
        batch.delete(document.reference);
        operationCount++;
      }
    }

    if (operationCount > 500) {
      throw StateError('Too many operations to synchronize in one batch.');
    }

    batch.set(collection.doc(newDocumentId), todo.toJson());

    await batch.commit();
  }

  Future<void> saveTodos(String uid, List<Todo> todos) async {
    final collection = _todosCollection(uid);
    final existing = await collection.get();
    final batch = _firestore.batch();

    final documentIds = <String, Todo>{};

    for (final todo in todos) {
      documentIds[_documentIdFor(todo)] = todo;
    }

    var operationCount = 0;

    for (final document in existing.docs) {
      if (!documentIds.containsKey(document.id)) {
        batch.delete(document.reference);
        operationCount++;
      }
    }

    for (final entry in documentIds.entries) {
      batch.set(collection.doc(entry.key), entry.value.toJson());
      operationCount++;
    }

    if (operationCount > 500) {
      throw StateError(
        'Too many operations to synchronize in one batch. '
        'Please contact the app developer.',
      );
    }

    await batch.commit();
  }

  Future<void> deleteTodo(String uid, String todoId) async {
    final collection = _todosCollection(uid);
    final snapshot = await collection.get();
    final batch = _firestore.batch();

    var operationCount = 0;

    for (final document in snapshot.docs) {
      final data = document.data();
      final storedTodoId = data['id'] ?? document.id;

      if (storedTodoId == todoId) {
        batch.delete(document.reference);
        operationCount++;
      }
    }

    if (operationCount > 500) {
      throw StateError('Too many operations to delete in one batch.');
    }

    if (operationCount > 0) {
      await batch.commit();
    }
  }
}
