import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../services/api.dart';
import '../services/local_store.dart';
import '../services/notifications.dart';
import 'auth_provider.dart';

class NewBooking {
  const NewBooking({
    required this.service,
    required this.vehicleName,
    required this.category,
    required this.city,
    required this.address,
    required this.date,
    required this.slotId,
    required this.name,
    required this.mobile,
    this.instructions = '',
    this.latitude,
    this.longitude,
    this.addons = const [],
    this.promoCode = '',
    this.usePlan = false,
    this.useCredit = false,
    this.providesWaterElectricity = false,
    this.payOnline = false,
  });

  final String service;
  final String vehicleName;
  final String category;
  final String city;
  final String address;
  final String date;
  final String slotId;
  final String name;
  final String mobile;
  final String instructions;
  final double? latitude;
  final double? longitude;
  final List<String> addons;
  final String promoCode;
  final bool usePlan;
  final bool useCredit;
  final bool providesWaterElectricity;
  final bool payOnline;

  Map<String, dynamic> quoteBody() => {
        'category': category,
        'service': service,
        'addons': addons,
        'city': city,
        'promoCode': promoCode,
        'usePlan': usePlan,
        'useCredit': useCredit,
        'providesWaterElectricity': providesWaterElectricity,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}

class Quote {
  const Quote({
    required this.base,
    required this.total,
    this.addons = const [],
    this.discount = 0,
    this.waterDiscount = 0,
    this.travelFee = 0,
    this.creditUsed = 0,
    this.planUsed = false,
  });

  final int base;
  final int total;
  final List<BookingAddon> addons;
  final int discount;
  final int waterDiscount;
  final int travelFee;
  final int creditUsed;
  final bool planUsed;

  int get addonTotal => addons.fold(0, (sum, row) => sum + row.price);

  factory Quote.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.round() ?? 0;
    final addons = json['addons'];
    return Quote(
      base: read('base'),
      total: read('total'),
      discount: read('discount'),
      waterDiscount: read('waterElectricityDiscount'),
      travelFee: read('travelFee'),
      creditUsed: read('creditUsed'),
      planUsed: json['planUsed'] == true,
      addons: addons is List
          ? addons.whereType<Map>().map((row) => BookingAddon('${row['name']}', (row['price'] as num?)?.round() ?? 0)).toList()
          : const [],
    );
  }
}

/// The signed-in person's bookings and everything they can do with one.
class BookingsProvider extends ChangeNotifier {
  BookingsProvider(this._store, this._auth) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final LocalStore _store;
  final AuthProvider _auth;

  String? _userId;
  List<Booking> _bookings = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  Timer? _poll;

  List<Booking> get bookings => _bookings;
  List<Booking> get upcoming => _bookings.where((row) => row.isUpcoming).toList()
    ..sort((a, b) => '${a.date}${a.timeSlot}'.compareTo('${b.date}${b.timeSlot}'));
  List<Booking> get completed => _bookings.where((row) => row.isCompleted).toList();
  List<Booking> get cancelled => _bookings.where((row) => row.isCancelled).toList();
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  Booking? byId(String id) {
    for (final row in _bookings) {
      if (row.id == id) return row;
    }
    return null;
  }

  @override
  void dispose() {
    _poll?.cancel();
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    final id = _auth.isSignedIn ? _auth.user!.id : null;
    if (id == _userId) return;
    _userId = id;
    _error = null;
    _loaded = false;
    _bookings = id == null ? const [] : _store.bookings(id);
    notifyListeners();
    if (id != null) {
      refresh();
      startPolling();
    } else {
      stopPolling();
    }
  }

  /// One timer for the whole app, run while it is in the foreground.
  void startPolling() {
    if (_userId == null) return;
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => refresh(quiet: true));
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> refresh({bool quiet = false}) async {
    final userId = _userId;
    if (userId == null || (_loading && quiet)) return;
    _loading = true;
    if (!quiet) notifyListeners();
    try {
      final rows = dataList(await Api.instance.get('/booking/mine')).map(Booking.fromJson).toList();
      if (_userId != userId) return;
      _announceChanges(rows);
      _bookings = rows;
      _error = null;
      _loaded = true;
      await _store.setBookings(userId, rows);
    } catch (error) {
      if (!quiet) _error = errorText(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _announceChanges(List<Booking> next) {
    if (!_loaded) return;
    final before = {for (final row in _bookings) row.id: row};
    for (final row in next) {
      final old = before[row.id];
      if (old == null) continue;
      if (old.status != row.status) {
        Notifications.show('Wash update', '${row.service} · ${row.statusLabel}');
      } else if (!old.isPaid && row.isPaid) {
        Notifications.show('Payment received', 'Thanks! ${row.service} is paid.');
      }
    }
  }

  /// Reads one booking from the server, falling back to the cached copy.
  Future<Booking?> fetch(String id) async {
    try {
      final booking = Booking.fromJson(dataMap(await Api.instance.get('/booking/$id')));
      _replace(booking);
      return booking;
    } on ApiException catch (error) {
      // Older API without GET /booking/:id: reload the list instead.
      if (error.isNotFound) await refresh(quiet: true);
      final cached = byId(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  void _replace(Booking booking) {
    final index = _bookings.indexWhere((row) => row.id == booking.id);
    final next = [..._bookings];
    if (index >= 0) {
      next[index] = booking;
    } else {
      next.insert(0, booking);
    }
    _bookings = next;
    final userId = _userId;
    if (userId != null) _store.setBookings(userId, next);
    notifyListeners();
  }

  Future<Quote> quote(NewBooking booking) async {
    final response = await Api.instance.post('/catalog/quote', booking.quoteBody());
    return Quote.fromJson(dataMap(response));
  }

  /// Booked-out slot ids for a day in a city.
  Future<Set<String>> fullSlots(String date, String city) async {
    try {
      final response = await Api.instance.get('/booking/booked-slots', query: {'date': date, 'city': city});
      final rows = response['bookedSlots'];
      return rows is List ? rows.map((row) => '$row').toSet() : <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<Booking> create(NewBooking booking) async {
    final lead = await Api.instance.post('/booking/lead', {
      'mobile': booking.mobile,
      'fullName': booking.name,
      'bookingSource': 'app',
    });
    final leadId = '${dataMap(lead)['_id'] ?? ''}';
    if (leadId.isEmpty) throw const ApiException('The booking could not be started. Try again.');
    final response = await Api.instance.put('/booking/$leadId', {
      'carModel': {'name': booking.vehicleName, 'category': booking.category},
      'service': booking.service,
      'location': {
        'address': booking.address,
        'pincode': '',
        'city': booking.city,
        if (booking.latitude != null) 'latitude': booking.latitude,
        if (booking.longitude != null) 'longitude': booking.longitude,
      },
      'date': booking.date,
      'timeSlot': booking.slotId,
      'customerDetails': {
        'fullName': booking.name,
        'mobile': booking.mobile,
        'instructions': booking.instructions,
      },
      'paymentMethod': booking.payOnline ? 'Online' : 'Cash',
      'paymentStatus': 'pending',
      'bookingSource': 'app',
      'useServerPrice': true,
      'addons': booking.addons,
      if (booking.promoCode.trim().isNotEmpty) 'promoCode': booking.promoCode.trim(),
      'usePlan': booking.usePlan,
      'useCredit': booking.useCredit,
      'providesWaterElectricity': booking.providesWaterElectricity,
    });
    final saved = Booking.fromJson(dataMap(response));
    if (saved.id.isEmpty) throw const ApiException('The booking was not saved. Try again.');
    _replace(saved);
    return saved;
  }

  Future<void> cancel(String id, {String reason = ''}) async {
    final response = await Api.instance.put('/booking/$id/cancel', {'reason': reason});
    _replace(Booking.fromJson(dataMap(response)));
  }

  Future<void> reschedule(String id, String date, String slotId) async {
    final response = await Api.instance.put('/booking/$id/reschedule', {'date': date, 'timeSlot': slotId});
    _replace(Booking.fromJson(dataMap(response)));
  }

  Future<void> rate(String id, int rating, String review) async {
    final response = await Api.instance.put('/booking/$id/rate', {'rating': rating, 'review': review});
    _replace(Booking.fromJson(dataMap(response)));
  }

  /// Returns the payment page for an unpaid booking.
  Future<String> payLink(String id) async {
    final response = await Api.instance.post('/booking/$id/pay');
    final url = '${response['paymentUrl'] ?? dataMap(response)['paymentUrl'] ?? ''}';
    final data = dataMap(response);
    if (data.isNotEmpty) _replace(Booking.fromJson(data));
    if (url.startsWith('http')) return url;
    throw const ApiException('The payment page is not ready. You can pay the washer at the car.');
  }

  Future<void> report(String id, String note, String image) async {
    final response = await Api.instance.post('/booking/$id/report', {'note': note, 'image': image});
    _replace(Booking.fromJson(dataMap(response)));
  }

  Future<List<SupportMessage>> messages(String id) async {
    final myId = _auth.user?.id ?? '';
    return dataList(await Api.instance.get('/booking/$id/messages'))
        .map((row) => SupportMessage.fromJson(row, myId))
        .toList();
  }

  Future<void> sendMessage(String id, String body) => Api.instance.post('/booking/$id/messages', {'body': body});

  Future<Map<String, dynamic>> receipt(String id) async => dataMap(await Api.instance.get('/booking/$id/receipt'));
}
