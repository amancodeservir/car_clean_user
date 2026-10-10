import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_booking.dart';

class OrderStore {
  static const String _ordersKey = 'local_orders_v1';
  static const String _cityKey = 'selected_city';
  static const String _vehicleKey = 'selected_vehicle';
  static const String _addressKey = 'saved_address';
  static const int _maxOrders = 50;

  static Future<List<SavedBooking>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final orders = <SavedBooking>[];
      for (final item in decoded) {
        if (item is Map) {
          orders.add(SavedBooking.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return orders;
    } catch (_) {
      return [];
    }
  }

  static Future<void> replaceOrders(List<SavedBooking> orders) async {
    final trimmed =
        orders.length > _maxOrders ? orders.sublist(0, _maxOrders) : orders;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersKey,
      jsonEncode(trimmed.map((order) => order.toJson()).toList()),
    );
  }

  static Future<void> addOrder(SavedBooking booking) async {
    final orders = await loadOrders();
    orders.insert(0, booking);
    final trimmed =
        orders.length > _maxOrders ? orders.sublist(0, _maxOrders) : orders;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersKey,
      jsonEncode(trimmed.map((order) => order.toJson()).toList()),
    );
  }

  static Future<String?> loadCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey);
  }

  static Future<void> saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, city);
  }

  static Future<String?> loadVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vehicleKey);
  }

  static Future<void> saveVehicle(String vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, vehicle);
  }

  static Future<String?> loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_addressKey);
  }

  static Future<void> saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address);
  }
}
