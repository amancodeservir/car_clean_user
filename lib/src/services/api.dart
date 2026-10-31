import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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
  Api._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  static final instance = Api._();

  static const _timeout = Duration(seconds: 25);

  late final Dio _dio;

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

    final auth = token;
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
      if (auth != null && auth.isNotEmpty) 'Authorization': 'Bearer $auth',
    };

    Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        uri.toString(),
        data: body,
        options: Options(
          method: method,
          headers: headers,
          validateStatus: (status) => status != null && status >= 200 && status < 300,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ApiException(
          'The server took too long to answer. Check your connection and try again.',
        );
      }

      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        throw const ApiException(
          'You appear to be offline. Check your connection and try again.',
        );
      }

      final res = e.response;
      if (res != null) {
        final statusCode = res.statusCode ?? 0;
        final decoded = _decodeResponse(res.data);
        final message = '${decoded['message'] ?? ''}'.trim();
        if (statusCode == 401 && auth != null && auth.isNotEmpty) {
          onUnauthorized?.call();
        }
        throw ApiException(
          message.isNotEmpty ? message : _fallback(statusCode),
          statusCode: statusCode,
        );
      }

      throw ApiException(
        e.message?.isNotEmpty == true ? e.message! : 'Something went wrong',
        statusCode: 0,
      );
    }

    return _decodeResponse(response.data);
  }

  static Map<String, dynamic> _decodeResponse(dynamic data) {
    if (data == null) return const {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final value = jsonDecode(data);
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value);
      } catch (_) {
        return const {};
      }
    }
    return const {};
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
