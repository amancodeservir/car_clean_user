import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode = 0});

  final String message;
  final int statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isOffline => statusCode == 0;

  @override
  String toString() => message;
}

/// The one HTTP client for the app. Holds the session token and turns every
/// failure into an [ApiException] with a message fit to show the customer.
class Api {
  Api._();

  static final instance = Api._();

  static const _timeout = Duration(seconds: 25);

  final http.Client _client = http.Client();

  String? token;

  /// Called when the server rejects the saved token.
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body: body ?? const {});

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) =>
      _send('PUT', path, body: body ?? const {});

  Future<Map<String, dynamic>> delete(String path, [Map<String, dynamic>? body]) =>
      _send('DELETE', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    var uri = Uri.parse('${AppConfig.apiBase}$path');
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json; charset=UTF-8';
    final auth = token;
    if (auth != null && auth.isNotEmpty) request.headers['Authorization'] = 'Bearer $auth';
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('The server took too long to answer. Check your connection and try again.');
    } on http.ClientException {
      // package:http wraps socket errors (offline, DNS) in ClientException.
      throw const ApiException('You appear to be offline. Check your connection and try again.');
    }

    Map<String, dynamic> decoded = const {};
    if (response.body.isNotEmpty) {
      try {
        final value = jsonDecode(response.body);
        if (value is Map) decoded = Map<String, dynamic>.from(value);
      } catch (_) {
        decoded = const {};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    final message = '${decoded['message'] ?? ''}'.trim();
    if (response.statusCode == 401 && auth != null && auth.isNotEmpty) {
      onUnauthorized?.call();
    }
    throw ApiException(
      message.isNotEmpty ? message : _fallback(response.statusCode),
      statusCode: response.statusCode,
    );
  }

  static String _fallback(int status) {
    if (status == 401) return 'Please sign in again.';
    if (status == 403) return 'You do not have access to this.';
    if (status == 404) return 'That was not found.';
    if (status >= 500) return 'Something went wrong on our side. Try again in a moment.';
    return 'Request failed ($status).';
  }
}

/// Text for any error, without the `Exception:` prefix.
String errorText(Object error) {
  if (error is ApiException) return error.message;
  final text = error.toString().replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
  return text.isEmpty ? 'Something went wrong' : text;
}

Map<String, dynamic> dataMap(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
}

List<Map<String, dynamic>> dataList(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is! List) return const [];
  return data.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
}
