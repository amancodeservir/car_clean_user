import 'package:flutter/foundation.dart';

import '../models/address.dart';
import '../models/catalog.dart';
import '../models/vehicle.dart';
import '../services/api.dart';
import '../services/local_store.dart';
import 'auth_provider.dart';
import 'catalog_provider.dart';

class PlanState {
  const PlanState({
    this.planName = '',
    this.washesLeft = 0,
    this.expiresAt,
    this.credit = 0,
    this.referralCode = '',
    this.pendingPlan = '',
    this.pendingUrl = '',
    this.paymentsEnabled = true,
  });

  final String planName;
  final int washesLeft;
  final DateTime? expiresAt;
  final int credit;
  final String referralCode;
  final String pendingPlan;
  final String pendingUrl;
  final bool paymentsEnabled;

  bool get isActive => planName.isNotEmpty && washesLeft > 0 && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
}

class AlertItem {
  const AlertItem({required this.title, required this.body, required this.at, required this.read, this.bookingId = ''});

  final String title;
  final String body;
  final String at;
  final bool read;
  final String bookingId;
}

/// The signed-in person's garage, saved addresses, wash plan and alerts.
/// Guests get one vehicle kept on the phone so prices still match their car.
class AccountProvider extends ChangeNotifier {
  AccountProvider(this._store, this._auth, this._catalog) {
    _guestVehicle = _store.guestVehicle;
    _selectedId = _store.selectedVehicleId;
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final LocalStore _store;
  final AuthProvider _auth;
  final CatalogProvider _catalog;

  String? _userId;
  List<Vehicle> _vehicles = const [];
  Vehicle? _guestVehicle;
  String? _selectedId;
  List<SavedAddress> _addresses = const [];
  bool _addressesFromServer = true;
  PlanState _plan = const PlanState();
  List<AlertItem> _alerts = const [];
  int _unread = 0;
  bool _loading = false;

  List<Vehicle> get vehicles => _auth.isSignedIn ? _vehicles : [if (_guestVehicle != null) _guestVehicle!];
  List<SavedAddress> get addresses => _addresses;
  PlanState get plan => _plan;
  List<AlertItem> get alerts => _alerts;
  int get unread => _unread;
  bool get loading => _loading;

  Vehicle? get vehicle {
    final list = vehicles;
    if (list.isEmpty) return null;
    for (final row in list) {
      if (row.id.isNotEmpty && row.id == _selectedId) return row;
    }
    for (final row in list) {
      if (row.isDefault) return row;
    }
    return list.first;
  }

  SavedAddress? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere((row) => row.isDefault, orElse: () => _addresses.first);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    final id = _auth.isSignedIn ? _auth.user!.id : null;
    if (id == _userId) {
      // Same person, maybe a fresher profile.
      if (id != null && !_addressesFromServer) _addresses = _fallbackAddresses();
      return;
    }
    _userId = id;
    _vehicles = const [];
    _addresses = const [];
    _plan = const PlanState();
    _alerts = const [];
    _unread = 0;
    notifyListeners();
    if (id != null) refresh(firstLoad: true);
  }

  Future<void> refresh({bool firstLoad = false}) async {
    if (!_auth.isSignedIn) return;
    _loading = true;
    notifyListeners();
    await Future.wait([
      _loadVehicles(uploadGuest: firstLoad),
      _loadAddresses(),
      refreshPlan(),
      refreshUnread(),
    ]);
    final home = defaultAddress;
    if (firstLoad && home != null) await _catalog.setCity(home.city);
    _loading = false;
    notifyListeners();
  }

  // Vehicles

  Future<void> _loadVehicles({bool uploadGuest = false}) async {
    try {
      _vehicles = dataList(await Api.instance.get('/account/vehicles')).map(Vehicle.fromJson).toList();
      final guest = _guestVehicle;
      if (uploadGuest && guest != null && _vehicles.isEmpty) {
        await addVehicle(guest.name, guest.category, plate: guest.plate);
      }
      if (guest != null && _vehicles.isNotEmpty) {
        _guestVehicle = null;
        await _store.setGuestVehicle(null);
      }
    } catch (error) {
      debugPrint('Vehicles were not loaded: $error');
    }
    notifyListeners();
  }

  Future<Vehicle> addVehicle(String name, String category, {String plate = ''}) async {
    if (!_auth.isSignedIn) {
      final vehicle = Vehicle(name: name.trim(), category: category, plate: plate.trim().toUpperCase(), isDefault: true);
      _guestVehicle = vehicle;
      await _store.setGuestVehicle(vehicle);
      notifyListeners();
      return vehicle;
    }
    final response = await Api.instance.post('/account/vehicles', {
      'name': name.trim(),
      'category': category,
      'plate': plate.trim(),
      'isDefault': true,
    });
    final vehicle = Vehicle.fromJson(dataMap(response));
    _vehicles = [vehicle, ..._vehicles.map((row) => Vehicle(id: row.id, name: row.name, category: row.category, plate: row.plate))];
    await selectVehicle(vehicle);
    return vehicle;
  }

  Future<void> selectVehicle(Vehicle vehicle) async {
    _selectedId = vehicle.id.isEmpty ? null : vehicle.id;
    await _store.setSelectedVehicleId(_selectedId);
    notifyListeners();
    if (vehicle.id.isNotEmpty && _auth.isSignedIn) {
      try {
        await Api.instance.put('/account/vehicles/${vehicle.id}/default');
      } catch (_) {
        // Older API without this route; the choice is still kept on the phone.
      }
    }
  }

  Future<void> removeVehicle(Vehicle vehicle) async {
    if (!vehicle.isSaved) {
      _guestVehicle = null;
      await _store.setGuestVehicle(null);
      notifyListeners();
      return;
    }
    await Api.instance.delete('/account/vehicles/${vehicle.id}');
    _vehicles = _vehicles.where((row) => row.id != vehicle.id).toList();
    if (_selectedId == vehicle.id) {
      _selectedId = null;
      await _store.setSelectedVehicleId(null);
    }
    notifyListeners();
  }

  // Addresses

  List<SavedAddress> _fallbackAddresses() {
    final user = _auth.user;
    if (user == null || user.address.trim().isEmpty) return const [];
    return [
      SavedAddress(id: 'profile', label: 'Home', address: user.address, city: user.city, isDefault: true),
    ];
  }

  Future<void> _loadAddresses() async {
    try {
      final rows = dataList(await Api.instance.get('/account/addresses'));
      _addresses = rows.map(SavedAddress.fromJson).toList();
      _addressesFromServer = true;
      if (_addresses.isEmpty) {
        // Carry the single address from the old profile into the list.
        final legacy = _fallbackAddresses();
        if (legacy.isNotEmpty && legacy.first.city.isNotEmpty) {
          try {
            await addAddress(label: 'Home', address: legacy.first.address, city: legacy.first.city);
          } catch (_) {}
        }
      }
    } on ApiException catch (error) {
      if (error.isNotFound) {
        _addressesFromServer = false;
        _addresses = _fallbackAddresses();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<SavedAddress> addAddress({
    required String label,
    required String address,
    required String city,
    double? latitude,
    double? longitude,
    bool makeDefault = false,
  }) async {
    if (!_addressesFromServer) {
      final user = _auth.user!;
      await _auth.updateProfile(name: user.name, phone: user.phone, city: city, address: address);
      _addresses = _fallbackAddresses();
      notifyListeners();
      return _addresses.first;
    }
    final rows = dataList(await Api.instance.post('/account/addresses', {
      'label': label,
      'address': address,
      'city': city,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isDefault': makeDefault,
    }));
    _addresses = rows.map(SavedAddress.fromJson).toList();
    notifyListeners();
    return _addresses.last;
  }

  Future<void> setDefaultAddress(SavedAddress address) async {
    if (!_addressesFromServer) return;
    final rows = dataList(await Api.instance.put('/account/addresses/${address.id}/default'));
    _addresses = rows.map(SavedAddress.fromJson).toList();
    await _catalog.setCity(address.city);
    notifyListeners();
  }

  Future<void> removeAddress(SavedAddress address) async {
    if (!_addressesFromServer) {
      final user = _auth.user!;
      await _auth.updateProfile(name: user.name, phone: user.phone, address: '');
      _addresses = const [];
      notifyListeners();
      return;
    }
    final rows = dataList(await Api.instance.delete('/account/addresses/${address.id}'));
    _addresses = rows.map(SavedAddress.fromJson).toList();
    notifyListeners();
  }

  // Plan and referral

  Future<void> refreshPlan() async {
    if (!_auth.isSignedIn) return;
    try {
      final data = dataMap(await Api.instance.get('/account/plan'));
      final pending = data['pendingPlan'];
      _plan = PlanState(
        planName: '${data['planName'] ?? ''}',
        washesLeft: (data['washesLeft'] as num?)?.round() ?? 0,
        expiresAt: DateTime.tryParse('${data['expiresAt'] ?? ''}')?.toLocal(),
        credit: (data['credit'] as num?)?.round() ?? 0,
        referralCode: '${data['referralCode'] ?? ''}',
        pendingPlan: pending is Map ? '${pending['name'] ?? ''}' : '',
        pendingUrl: pending is Map ? '${pending['url'] ?? ''}' : '',
        paymentsEnabled: data['paymentsEnabled'] != false,
      );
      notifyListeners();
    } catch (error) {
      debugPrint('Plan was not loaded: $error');
    }
  }

  /// Starts a plan purchase and returns the payment page to open.
  Future<String> buyPlan(WashPlan plan) async {
    final response = await Api.instance.post('/account/plan', {'name': plan.name});
    final url = '${response['paymentUrl'] ?? ''}';
    await refreshPlan();
    if (url.startsWith('http')) return url;
    throw const ApiException('The payment page could not be opened. Try again in a moment.');
  }

  Future<String> applyReferral(String code) async {
    final response = await Api.instance.post('/account/referral', {'code': code.trim().toUpperCase()});
    await refreshPlan();
    await _auth.refresh();
    return '${response['message'] ?? 'Referral added'}';
  }

  // Alerts

  Future<void> refreshUnread() async {
    if (!_auth.isSignedIn) return;
    try {
      final response = await Api.instance.get('/account/notifications');
      _unread = (response['unread'] as num?)?.round() ?? 0;
      _alerts = dataList(response)
          .map((row) => AlertItem(
                title: '${row['title'] ?? ''}',
                body: '${row['body'] ?? ''}',
                at: '${row['createdAt'] ?? ''}',
                read: row['read'] == true,
                bookingId: '${row['booking'] ?? ''}',
              ))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAlertsRead() async {
    if (_unread == 0) return;
    try {
      await Api.instance.put('/account/notifications/read');
      _unread = 0;
      notifyListeners();
    } catch (_) {}
  }
}
