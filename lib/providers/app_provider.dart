import 'package:flutter/foundation.dart';

import '../data/service_catalog.dart';
import '../models/saved_booking.dart';
import '../services/api_service.dart';
import '../services/order_store.dart';
import '../services/wash_alerts.dart';
import '../utils/constants.dart';

class AppProvider extends ChangeNotifier {
  AppProvider() {
    _load();
  }

  String _city = 'Lucknow';
  String _vehicle = 'CAR';
  String _address = '';
  List<SavedBooking> _orders = [];
  bool _isReady = false;
  final Map<String, int> _prices = {};
  final Map<String, int> _addonPrices = {};
  List<String> _addons = [];
  int _unread = 0;

  String get city => _city;
  String get vehicle => _vehicle;
  String get address => _address;
  List<SavedBooking> get orders => List<SavedBooking>.unmodifiable(_orders);
  bool get isReady => _isReady;
  List<String> get addons => List.unmodifiable(_addons);
  int addonPrice(String name) => _addonPrices[name] ?? 0;
  int get unread => _unread;

  int priceFor({required String category, required String service}) {
    return _prices['$category|$service'] ??
        ServiceCatalog.priceFor(category: category, service: service);
  }

  String fromPrice(String service) {
    final category = _vehicle == 'BIKE' ? 'Bike' : 'Compact';
    final amount = priceFor(category: category, service: service);
    return amount == 0 ? '' : 'from ₹$amount';
  }

  Future<void> setCity(String city) async {
    await OrderStore.saveCity(city);
    _city = city;
    notifyListeners();
  }

  Future<void> setVehicle(String vehicle) async {
    await OrderStore.saveVehicle(vehicle);
    _vehicle = vehicle;
    notifyListeners();
  }

  Future<void> setAddress(String address) async {
    await OrderStore.saveAddress(address);
    _address = address;
    notifyListeners();
  }

  Future<void> addOrder(SavedBooking booking) async {
    await OrderStore.addOrder(booking);
    _orders = await OrderStore.loadOrders();
    notifyListeners();
  }

  Future<void> syncOrders(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      final previous = {for (final order in _orders) order.id: order.status};
      final remote = await ApiService.myBookings(token);
      _orders = remote;
      await OrderStore.replaceOrders(remote);
      notifyListeners();
      for (final order in remote) {
        final before = previous[order.id];
        if (before != null && before.isNotEmpty && before != order.status) {
          await WashAlerts.show(
            'Wash update',
            '${order.service} is now ${order.status.replaceAll('_', ' ')}',
          );
        }
      }
    } catch (_) {
      notifyListeners();
    }
  }

  Future<String?> cancelOrder(String token, String id) async {
    try {
      await ApiService.cancelBooking(token, id);
      await syncOrders(token);
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _load() async {
    try {
      final city = await OrderStore.loadCity();
      final vehicle = await OrderStore.loadVehicle();
      final address = await OrderStore.loadAddress();
      final orders = await OrderStore.loadOrders();
      if (city != null) _city = city;
      if (vehicle != null) _vehicle = vehicle;
      if (address != null) _address = address;
      _orders = orders;
      await _loadCatalog();
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final response = await ApiService.getJson(AppConstants.catalog, '');
      final data = response['data'];
      if (data is! Map) return;
      final rows = data['prices'];
      if (rows is List) {
        _prices.clear();
        for (final row in rows) {
          if (row is! Map) continue;
          final category = row['category']?.toString() ?? '';
          final service = row['service']?.toString() ?? '';
          final amount = row['amount'];
          final price = amount is num ? amount.round() : int.tryParse('$amount') ?? 0;
          if (category.isNotEmpty && service.isNotEmpty) {
            _prices['$category|$service'] = price;
          }
        }
      }
      final addons = data['addons'];
      if (addons is List) {
        _addons = [];
        _addonPrices.clear();
        for (final addon in addons) {
          if (addon is! Map || addon['name'] == null) continue;
          final name = addon['name'].toString();
          final amount = addon['amount'];
          _addons.add(name);
          _addonPrices[name] = amount is num ? amount.round() : int.tryParse('$amount') ?? 0;
        }
      }
    } catch (_) {}
  }

  Future<void> refreshUnread(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      final response = await ApiService.getJson(AppConstants.notifications, token);
      final unread = response['unread'];
      _unread = unread is num ? unread.round() : 0;
      notifyListeners();
    } catch (_) {}
  }
}
