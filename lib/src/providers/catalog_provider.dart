import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/defaults.dart';
import '../models/catalog.dart';
import '../services/api.dart';
import '../services/local_store.dart';

/// Services, prices, add-ons, plans and the serviceable cities. Starts from
/// the built-in defaults and swaps in the live catalog once it loads.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._store) {
    final saved = _store.city;
    if (saved != null && _cities.any((city) => city.name == saved)) _city = saved;
  }

  final LocalStore _store;

  List<ServiceInfo> _services = Defaults.services;
  Map<String, int> _prices = Defaults.prices;
  Map<String, int> _basePrices = Defaults.prices;
  Map<String, ServiceStats> _stats = const {};
  List<Addon> _addons = Defaults.addons;
  List<WashPlan> _plans = Defaults.plans;
  List<City> _cities = Defaults.cities;
  double _zoneKm = Defaults.zoneKm;
  String _festival = '';
  bool _live = false;
  bool _loading = false;
  String _city = 'Lucknow';

  List<ServiceInfo> get services => _services.where((service) => offers(service.name)).toList();
  List<Addon> get addons => _addons;
  List<WashPlan> get plans => _plans;
  List<City> get cities => _cities;
  String get city => _city;
  bool get isLive => _live;
  bool get loading => _loading;

  /// Name of a running festival offer, or empty.
  String get festival => _festival;

  ServiceStats stats(String service) => _stats[service] ?? const ServiceStats();

  ServiceInfo? service(String name) {
    for (final row in _services) {
      if (row.name == name) return row;
    }
    return null;
  }

  /// True when the service has at least one active price.
  bool offers(String service) => _prices.keys.any((key) => key.endsWith('|$service') && (_prices[key] ?? 0) > 0);

  PriceTag price(String service, String category) {
    final amount = _prices['$category|$service'] ?? 0;
    final before = _basePrices['$category|$service'] ?? 0;
    return PriceTag(amount, before);
  }

  /// Lowest price across car sizes (or the bike price), for "from ₹…" labels.
  PriceTag startingPrice(String service, {bool bike = false}) {
    if (bike) return price(service, 'Bike');
    PriceTag? best;
    for (final category in Defaults.carCategories) {
      final tag = price(service, category);
      if (!tag.isKnown) continue;
      if (best == null || tag.amount < best.amount) best = tag;
    }
    return best ?? const PriceTag(0);
  }

  int addonPrice(String name) {
    for (final addon in _addons) {
      if (addon.name == name) return addon.amount;
    }
    return 0;
  }

  Future<void> setCity(String name) async {
    if (!_cities.any((city) => city.name == name)) return;
    _city = name;
    await _store.setCity(name);
    notifyListeners();
  }

  /// The closest serviceable city, or null when [latitude]/[longitude] is
  /// outside every service zone.
  City? nearestCity(double latitude, double longitude) {
    City? best;
    var bestKm = double.infinity;
    for (final city in _cities) {
      final km = distanceKm(city.latitude, city.longitude, latitude, longitude);
      if (km < bestKm) {
        bestKm = km;
        best = city;
      }
    }
    return bestKm <= _zoneKm ? best : null;
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final data = dataMap(await Api.instance.get('/catalog'));
      _apply(data);
      _live = true;
    } catch (error) {
      debugPrint('Catalog stayed on defaults: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _apply(Map<String, dynamic> data) {
    final prices = data['prices'];
    if (prices is List && prices.isNotEmpty) {
      final next = <String, int>{};
      for (final row in prices.whereType<Map>()) {
        if (row['active'] == false) continue;
        final amount = row['amount'];
        next['${row['category']}|${row['service']}'] = amount is num ? amount.round() : 0;
      }
      _prices = next;
      _basePrices = next;
    }
    final base = data['basePrices'];
    if (base is List && base.isNotEmpty) {
      final next = <String, int>{};
      for (final row in base.whereType<Map>()) {
        final amount = row['amount'];
        next['${row['category']}|${row['service']}'] = amount is num ? amount.round() : 0;
      }
      _basePrices = next;
    }
    final services = data['services'];
    if (services is List && services.isNotEmpty) {
      _services = services.whereType<Map>().map((row) => ServiceInfo.fromJson(Map<String, dynamic>.from(row))).toList();
    }
    final stats = data['stats'];
    if (stats is Map) {
      _stats = {
        for (final entry in stats.entries)
          if (entry.value is Map) '${entry.key}': ServiceStats.fromJson(Map<String, dynamic>.from(entry.value as Map)),
      };
    }
    final addons = data['addons'];
    if (addons is List) {
      _addons = addons
          .whereType<Map>()
          .where((row) => row['active'] != false && row['name'] != null)
          .map((row) => Addon('${row['name']}', (row['amount'] as num?)?.round() ?? 0))
          .toList();
    }
    final plans = data['plans'];
    if (plans is List && plans.isNotEmpty) {
      _plans = plans.whereType<Map>().map((row) => WashPlan.fromJson(Map<String, dynamic>.from(row))).toList();
    }
    final cities = data['cities'];
    if (cities is List && cities.isNotEmpty) {
      _cities = cities.whereType<Map>().map((row) => City.fromJson(Map<String, dynamic>.from(row))).toList();
      if (!_cities.any((city) => city.name == _city)) _city = _cities.first.name;
    }
    final zone = data['zoneKm'];
    if (zone is num && zone > 0) _zoneKm = zone.toDouble();
    final festival = data['festival'];
    if (festival is Map && festival['isOfferActive'] == true) {
      final discount = festival['customDiscount'];
      final hasDiscount = discount is num && discount > 0;
      final name = '${festival['activeFestival'] ?? ''}'.trim();
      _festival = hasDiscount && name.isNotEmpty ? _titleCase(name) : '';
    } else {
      _festival = '';
    }
  }

  static String _titleCase(String text) => text
      .toLowerCase()
      .split(RegExp(r'[\s_]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earth = 6371.0;
  double rad(double value) => value * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
