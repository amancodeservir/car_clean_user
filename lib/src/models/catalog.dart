class ServiceInfo {
  const ServiceInfo({
    required this.name,
    required this.title,
    required this.tagline,
    required this.description,
    required this.durationMins,
    required this.inclusions,
    required this.group,
    this.popular = false,
  });

  /// The id the backend prices by, e.g. `Basic Wash`.
  final String name;

  /// What the customer sees, e.g. `Smart Wash`.
  final String title;
  final String tagline;
  final String description;
  final int durationMins;
  final List<String> inclusions;

  /// `wash`, `detailing` or `eco`.
  final String group;
  final bool popular;

  String get durationLabel {
    if (durationMins <= 0) return '';
    if (durationMins < 60) return '$durationMins mins';
    final hours = durationMins ~/ 60;
    final minutes = durationMins % 60;
    return minutes == 0 ? '$hours hr${hours > 1 ? 's' : ''}' : '$hours hr $minutes mins';
  }

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    final items = json['inclusions'];
    return ServiceInfo(
      name: '${json['name'] ?? ''}',
      title: '${json['title'] ?? json['name'] ?? ''}',
      tagline: '${json['tagline'] ?? ''}',
      description: '${json['description'] ?? ''}',
      durationMins: _int(json['durationMins']),
      inclusions: items is List ? items.map((item) => '$item').toList() : const [],
      group: '${json['group'] ?? 'wash'}',
      popular: json['popular'] == true,
    );
  }
}

class ServiceStats {
  const ServiceStats({this.bookings30d = 0, this.rating, this.ratingCount = 0});

  final int bookings30d;
  final double? rating;
  final int ratingCount;

  factory ServiceStats.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    return ServiceStats(
      bookings30d: _int(json['bookings30d']),
      rating: rating is num ? rating.toDouble() : null,
      ratingCount: _int(json['ratingCount']),
    );
  }
}

class City {
  const City(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      '${json['name'] ?? ''}',
      (json['latitude'] as num?)?.toDouble() ?? 0,
      (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Addon {
  const Addon(this.name, this.amount);

  final String name;
  final int amount;
}

class WashPlan {
  const WashPlan({required this.name, required this.washes, required this.amount, required this.service});

  final String name;
  final int washes;
  final int amount;
  final String service;

  int get perWash => washes == 0 ? amount : (amount / washes).round();

  factory WashPlan.fromJson(Map<String, dynamic> json) {
    return WashPlan(
      name: '${json['name'] ?? ''}',
      washes: _int(json['washes']),
      amount: _int(json['amount']),
      service: '${json['service'] ?? ''}',
    );
  }
}

/// A price and, when a real festival discount is on, the price before it.
class PriceTag {
  const PriceTag(this.amount, [this.before = 0]);

  final int amount;
  final int before;

  bool get isKnown => amount > 0;
  bool get hasDiscount => before > amount && amount > 0;
  int get percentOff => hasDiscount ? (((before - amount) / before) * 100).round() : 0;
}

int _int(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse('${value ?? ''}') ?? 0;
}
