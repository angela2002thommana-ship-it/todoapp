import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/todo.dart';
import 'auth_service.dart';

class ApiServiceException implements Exception {
  final String message;
  final int? statusCode;

  const ApiServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String projectId = 'todo-4617f';
  static const Duration requestTimeout = Duration(seconds: 15);

  Future<Map<String, String>> _authorizationHeaders({
    bool includeJsonContentType = false,
  }) async {
    final uid = AuthService.instance.currentUserId;
    final token = await AuthService.instance.idToken;

    if (uid == null || token == null) {
      throw const ApiServiceException(
        'Your session has expired. Please sign in again.',
      );
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
    };
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiServiceException(
        'The request took too long. Please try again.',
      );
    } on SocketException {
      throw const ApiServiceException(
        'No internet connection. Check your network and try again.',
      );
    } on http.ClientException {
      throw const ApiServiceException(
        'Could not connect to the server. Please check your internet connection.',
      );
    }
  }

  void _checkResponse(
    http.Response response, {
    required Set<int> successCodes,
    required String operation,
  }) {
    if (successCodes.contains(response.statusCode)) {
      return;
    }

    String? serverMessage;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            serverMessage = message.trim();
          }
        }
      }
    } on FormatException {
      // The response body was not JSON, so use the status-based message.
    }

    final message = switch (response.statusCode) {
      400 => 'The server rejected the request. Check the task details.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested task or resource could not be found.',
      408 => 'The server timed out. Please try again.',
      429 => 'Too many requests. Please wait a moment and try again.',
      >= 500 =>
        'The server is temporarily unavailable. Please try again later.',
      _ =>
        'Could not $operation. Server returned error ${response.statusCode}.',
    };

    final details = serverMessage == null ? '' : '\nDetails: $serverMessage';

    throw ApiServiceException(
      '$message$details',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _decodeDocument(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }

      return decoded;
    } on FormatException {
      throw const ApiServiceException(
        'The server returned an invalid response. Please try again.',
      );
    }
  }

  Future<List<Todo>> fetchTodos() async {
    final headers = await _authorizationHeaders();

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/'
          '${AuthService.instance.currentUserId}/todos',
    );

    final response = await _sendRequest(() => http.get(url, headers: headers));

    _checkResponse(response, successCodes: {200}, operation: 'load tasks');

    final responseData = _decodeDocument(response);
    final documents = responseData['documents'];

    if (documents == null) {
      return [];
    }

    if (documents is! List) {
      throw const ApiServiceException(
        'The server returned an unexpected task list.',
      );
    }

    try {
      return documents.map<Todo>((document) {
        if (document is! Map) {
          throw const FormatException('Invalid task document.');
        }

        final documentData = Map<String, dynamic>.from(document);
        final documentName = documentData['name'];

        if (documentName is! String || documentName.isEmpty) {
          throw const FormatException('Task document has no ID.');
        }

        final rawFields = documentData['fields'];
        if (rawFields is! Map) {
          throw const FormatException('Task document has invalid fields.');
        }

        final fields = Map<String, dynamic>.from(rawFields);
        final decodedFields = fields.map((key, value) {
          if (value is! Map) {
            throw const FormatException('Invalid Firestore field.');
          }

          return MapEntry(
            key,
            _decodeFirestoreValue(Map<String, dynamic>.from(value)),
          );
        });

        decodedFields['id'] = documentName.split('/').last;

        return Todo.fromJson(decodedFields);
      }).toList();
    } on ApiServiceException {
      rethrow;
    } catch (_) {
      throw const ApiServiceException(
        'Some task data could not be read. Check the stored task format.',
      );
    }
  }

  Future<void> createTodo(Todo todo) async {
    final headers = await _authorizationHeaders(includeJsonContentType: true);

    final uid = AuthService.instance.currentUserId!;

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/$uid/todos',
      {'documentId': todo.id},
    );

    final fields = todo.toJson().map((key, value) {
      return MapEntry(key, _encodeFirestoreValue(value));
    });

    final response = await _sendRequest(
      () => http.post(
        url,
        headers: headers,
        body: jsonEncode({'fields': fields}),
      ),
    );

    _checkResponse(response, successCodes: {200}, operation: 'create task');
  }

  Future<void> updateTodo(Todo todo) async {
    final headers = await _authorizationHeaders(includeJsonContentType: true);

    final uid = AuthService.instance.currentUserId!;
    final fieldsToUpdate = todo.toJson();

    final queryParameters = <String, dynamic>{
      'updateMask.fieldPaths': fieldsToUpdate.keys.toList(),
    };

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/$uid/todos/${todo.id}',
    ).replace(queryParameters: queryParameters);

    final fields = fieldsToUpdate.map((key, value) {
      return MapEntry(key, _encodeFirestoreValue(value));
    });

    final response = await _sendRequest(
      () => http.patch(
        url,
        headers: headers,
        body: jsonEncode({'fields': fields}),
      ),
    );

    _checkResponse(response, successCodes: {200}, operation: 'update task');
  }

  Future<void> deleteTodo(String todoId) async {
    final headers = await _authorizationHeaders();

    final uid = AuthService.instance.currentUserId!;

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/users/$uid/todos/$todoId',
    );

    final response = await _sendRequest(
      () => http.delete(url, headers: headers),
    );

    _checkResponse(
      response,
      successCodes: {200, 204},
      operation: 'delete task',
    );
  }

  Map<String, dynamic> _encodeFirestoreValue(dynamic value) {
    if (value == null) {
      return {'nullValue': null};
    }

    if (value is String) {
      return {'stringValue': value};
    }

    if (value is bool) {
      return {'booleanValue': value};
    }

    if (value is int) {
      return {'integerValue': value.toString()};
    }

    if (value is double) {
      return {'doubleValue': value};
    }

    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_encodeFirestoreValue).toList()},
      };
    }

    if (value is Map) {
      final fields = Map<String, dynamic>.from(value).map((key, item) {
        return MapEntry(key, _encodeFirestoreValue(item));
      });

      return {
        'mapValue': {'fields': fields},
      };
    }

    throw ApiServiceException(
      'Unsupported task data type: ${value.runtimeType}.',
    );
  }

  dynamic _decodeFirestoreValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) {
      return value['stringValue'];
    }

    if (value.containsKey('booleanValue')) {
      return value['booleanValue'];
    }

    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'].toString());
    }

    if (value.containsKey('doubleValue')) {
      return double.parse(value['doubleValue'].toString());
    }

    if (value.containsKey('nullValue')) {
      return null;
    }

    if (value.containsKey('arrayValue')) {
      final arrayValue = value['arrayValue'];

      if (arrayValue is! Map) {
        return [];
      }

      final values = arrayValue['values'];

      if (values == null) {
        return [];
      }

      if (values is! List) {
        throw const FormatException('Invalid Firestore array.');
      }

      return values.map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid Firestore array item.');
        }

        return _decodeFirestoreValue(Map<String, dynamic>.from(item));
      }).toList();
    }

    if (value.containsKey('mapValue')) {
      final mapValue = value['mapValue'];

      if (mapValue is! Map) {
        return <String, dynamic>{};
      }

      final fields = mapValue['fields'];

      if (fields == null) {
        return <String, dynamic>{};
      }

      if (fields is! Map) {
        throw const FormatException('Invalid Firestore map.');
      }

      return Map<String, dynamic>.from(fields).map((key, item) {
        if (item is! Map) {
          throw const FormatException('Invalid Firestore map value.');
        }

        return MapEntry(
          key,
          _decodeFirestoreValue(Map<String, dynamic>.from(item)),
        );
      });
    }

    return null;
  }
}
