import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/saved_booking.dart';
import '../utils/constants.dart';

class ApiService {
  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Booked slot strings for [date] (`YYYY-MM-DD`). Returns an empty list on
  /// any failure and does not throw.
  static Future<List<String>> getBookedSlots(String date, {String city = ''}) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.bookedSlots}')
          .replace(queryParameters: {
        'date': date,
        if (city.trim().isNotEmpty) 'city': city.trim(),
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return [];
      final slots = decoded['bookedSlots'];
      if (slots is! List) return [];
      return slots.map((slot) => slot.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Creates a booking lead and returns `data._id`.
  static Future<String> createLead({
    required String mobile,
    required String name,
    String? token,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.bookingLead}'),
        headers: _headers(token),
        body: jsonEncode({
          'mobile': mobile,
          'fullName': name,
          'bookingSource': 'app',
        }),
      ),
    );
    final data = _dataMap(response);
    final id = data?['_id']?.toString() ?? '';
    if (response.statusCode == 201 && id.isNotEmpty) return id;
    throw Exception(_serverMessage(response));
  }

  /// Finalizes a lead (`lead` -> `pending`) and returns the saved booking.
  static Future<SavedBooking> finalizeBooking({
    required String leadId,
    required String service,
    required String vehicleName,
    required String category,
    required String city,
    required String address,
    required String date,
    required String timeSlot,
    required String fullName,
    required String mobile,
    required String instructions,
    required int price,
    String? token,
    String paymentMethod = 'Cash',
    List<String> addons = const [],
    String promoCode = '',
    bool usePlan = false,
    bool useCredit = false,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _send(
      () => http.put(
        Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.booking(Uri.encodeComponent(leadId))}',
        ),
        headers: _headers(token),
        body: jsonEncode({
          'carModel': {
            'name': vehicleName,
            'category': category,
          },
          'service': service,
          'location': {
            'address': address,
            'pincode': '',
            'city': city,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          },
          'date': date,
          'timeSlot': timeSlot,
          'customerDetails': {
            'fullName': fullName,
            'mobile': mobile,
            'instructions': instructions,
          },
          'finalPrice': price,
          'paymentMethod': paymentMethod,
          'paymentStatus': 'pending',
          'bookingSource': 'app',
          'useServerPrice': true,
          'addons': addons,
          if (promoCode.trim().isNotEmpty) 'promoCode': promoCode.trim(),
          'usePlan': usePlan,
          'useCredit': useCredit,
        }),
      ),
    );
    final data = _dataMap(response);
    final id = data?['_id']?.toString() ?? '';
    if (response.statusCode != 200 || data == null || id.isEmpty) {
      throw Exception(_serverMessage(response));
    }

    return SavedBooking.fromServer(data);
  }

  static Future<List<SavedBooking>> myBookings(String token) async {
    final response = await _send(
      () => http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.myBookings}'),
        headers: _headers(token),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(_serverMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['data'] is! List) return [];
    return (decoded['data'] as List)
        .whereType<Map>()
        .map((item) => SavedBooking.fromServer(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> cancelBooking(String token, String id) async {
    final response = await _send(
      () => http.put(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.cancelBooking(id)}'),
        headers: _headers(token),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception(_serverMessage(response));
    }
  }

  static Future<String> payBooking(String token, String id) async {
    final response = await sendJson('POST', '/booking/$id/pay', token, {});
    final direct = response['paymentUrl']?.toString() ?? '';
    if (direct.startsWith('http')) return direct;
    final data = response['data'];
    if (data is Map && data['paymentUrl'] != null) {
      final url = data['paymentUrl'].toString();
      if (url.startsWith('http')) return url;
    }
    throw Exception('Payment link was not ready');
  }

  static Future<Map<String, dynamic>> getJson(String path, String token) async {
    final response = await _send(
      () => http.get(
        Uri.parse('${AppConstants.baseUrl}$path'),
        headers: _headers(token),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_serverMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  static Future<Map<String, dynamic>> sendJson(
    String method,
    String path,
    String? token,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final headers = _headers(token);
    final encoded = jsonEncode(body);
    final response = await _send(() {
      switch (method) {
        case 'POST':
          return http.post(uri, headers: headers, body: encoded);
        case 'PUT':
          return http.put(uri, headers: headers, body: encoded);
        case 'DELETE':
          return http.delete(uri, headers: headers);
        default:
          return http.get(uri, headers: headers);
      }
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_serverMessage(response));
    }
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  static Map<String, dynamic>? _dataMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }

  static String _serverMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        final message = decoded['message'].toString().trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}

