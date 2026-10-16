import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';
import '../models/vehicle.dart';

/// Everything the app keeps on the phone. Bookings are cached per account so
/// one person never sees another person's washes after a logout.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async => LocalStore(await SharedPreferences.getInstance());

  // Same key the old app used, so existing sessions survive the update.
  static const _token = 'jwt_token';
  static const _tour = 'ccp_walkthrough_seen';
  static const _city = 'selected_city';
  static const _guestVehicle = 'ccp_guest_vehicle';
  static const _selectedVehicle = 'ccp_selected_vehicle';
  static const _rememberEmail = 'ccp_remember_email';
  static String _bookingsKey(String userId) => 'ccp_bookings_$userId';

  String? get token => _prefs.getString(_token);
  Future<void> setToken(String? value) =>
      value == null || value.isEmpty ? _prefs.remove(_token) : _prefs.setString(_token, value);

  static const _user = 'ccp_user';

  Map<String, dynamic>? get user {
    final raw = _prefs.getString(_user);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setUser(Map<String, dynamic>? json) =>
      json == null ? _prefs.remove(_user) : _prefs.setString(_user, jsonEncode(json));

  bool get tourSeen => _prefs.getBool(_tour) ?? false;
  Future<void> setTourSeen() => _prefs.setBool(_tour, true);

  String? get city => _prefs.getString(_city);
  Future<void> setCity(String value) => _prefs.setString(_city, value);

  String? get rememberedEmail => _prefs.getString(_rememberEmail);
  Future<void> setRememberedEmail(String? value) =>
      value == null || value.isEmpty ? _prefs.remove(_rememberEmail) : _prefs.setString(_rememberEmail, value);

  Vehicle? get guestVehicle {
    final raw = _prefs.getString(_guestVehicle);
    if (raw == null) return null;
    try {
      return Vehicle.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> setGuestVehicle(Vehicle? vehicle) => vehicle == null
      ? _prefs.remove(_guestVehicle)
      : _prefs.setString(_guestVehicle, jsonEncode(vehicle.toJson()));

  String? get selectedVehicleId => _prefs.getString(_selectedVehicle);
  Future<void> setSelectedVehicleId(String? id) =>
      id == null || id.isEmpty ? _prefs.remove(_selectedVehicle) : _prefs.setString(_selectedVehicle, id);

  List<Booking> bookings(String userId) {
    final raw = _prefs.getString(_bookingsKey(userId));
    if (raw == null) return const [];
    try {
      final rows = jsonDecode(raw);
      if (rows is! List) return const [];
      return rows.whereType<Map>().map((row) => Booking.fromJson(Map<String, dynamic>.from(row))).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> setBookings(String userId, List<Booking> bookings) {
    final kept = bookings.take(60).map((booking) => booking.toJson()).toList();
    return _prefs.setString(_bookingsKey(userId), jsonEncode(kept));
  }

  /// Clears what belongs to the signed-in person. The tour flag and the city
  /// stay, they belong to the phone.
  Future<void> clearAccount() async {
    await setToken(null);
    await setUser(null);
    await _prefs.remove(_selectedVehicle);
    for (final key in _prefs.getKeys().where((key) => key.startsWith('ccp_bookings_')).toList()) {
      await _prefs.remove(key);
    }
    // Cache used by the previous version of the app.
    await _prefs.remove('local_orders_v1');
    await _prefs.remove('saved_address');
  }
}
