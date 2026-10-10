class SavedBooking {
  final String id;
  final String service;
  final String vehicleName;
  final String category;
  final String city;
  final String address;
  final String date;
  final String timeSlot;
  final int price;
  final String paymentMethod;
  final String status;
  final String createdAt;
  final String staffName;
  final String staffPhone;
  final String paymentStatus;
  final String paymentUrl;
  final int? rating;
  final String washerName;
  final String washerPhone;
  final List<OrderEvent> timeline;
  final List<OrderReport> reports;

  const SavedBooking({
    required this.id,
    required this.service,
    required this.vehicleName,
    required this.category,
    required this.city,
    required this.address,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.staffName = '',
    this.staffPhone = '',
    this.paymentStatus = '',
    this.paymentUrl = '',
    this.rating,
    this.washerName = '',
    this.washerPhone = '',
    this.timeline = const [],
    this.reports = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service,
      'vehicleName': vehicleName,
      'category': category,
      'city': city,
      'address': address,
      'date': date,
      'timeSlot': timeSlot,
      'price': price,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
      'staffName': staffName,
      'staffPhone': staffPhone,
      'paymentStatus': paymentStatus,
      'paymentUrl': paymentUrl,
      'rating': rating,
    };
  }

  factory SavedBooking.fromServer(Map<String, dynamic> json) {
    final car = json['carModel'] is Map
        ? Map<String, dynamic>.from(json['carModel'] as Map)
        : <String, dynamic>{};
    final location = json['location'] is Map
        ? Map<String, dynamic>.from(json['location'] as Map)
        : <String, dynamic>{};
    final assigned = json['assignedStaff'];
    final assignedMap = assigned is Map
        ? Map<String, dynamic>.from(assigned)
        : <String, dynamic>{};
    return SavedBooking.fromJson({
      '_id': json['_id'],
      'service': json['service'],
      'vehicleName': car['name'],
      'category': car['category'],
      'city': location['city'],
      'address': location['address'],
      'date': json['date'],
      'timeSlot': json['timeSlot'],
      'price': json['finalPrice'],
      'paymentMethod': json['paymentMethod'],
      'paymentStatus': json['paymentStatus'],
      'paymentUrl': json['paymentUrl'],
      'status': json['status'],
      'createdAt': json['createdAt'],
      'staffName': assignedMap['name'],
      'staffPhone': assignedMap['phone'],
      'rating': json['rating'],
      'washerName': json['washerName'] ?? assignedMap['name'],
      'washerPhone': json['washerPhone'] ?? assignedMap['phone'],
      'timeline': json['timeline'],
      'reports': json['reports'],
    });
  }

  factory SavedBooking.fromJson(Map<String, dynamic> json) {
    return SavedBooking(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      vehicleName: json['vehicleName']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      price: _readPrice(json['price']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      staffName: json['staffName']?.toString() ?? '',
      staffPhone: json['staffPhone']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      paymentUrl: json['paymentUrl']?.toString() ?? '',
      rating: json['rating'] is num ? (json['rating'] as num).round() : int.tryParse('${json['rating']}'),
      washerName: json['washerName']?.toString() ?? '',
      washerPhone: json['washerPhone']?.toString() ?? '',
      timeline: _events(json['timeline']),
      reports: _reports(json['reports']),
    );
  }

  static List<OrderEvent> _events(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      final row = Map<String, dynamic>.from(item);
      return OrderEvent(
        status: row['status']?.toString() ?? '',
        at: row['at']?.toString() ?? '',
        byName: row['byName']?.toString() ?? '',
        byRole: row['byRole']?.toString() ?? '',
      );
    }).toList();
  }

  static List<OrderReport> _reports(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      final row = Map<String, dynamic>.from(item);
      return OrderReport(
        note: row['note']?.toString() ?? '',
        image: row['image']?.toString() ?? '',
        at: row['at']?.toString() ?? '',
        byName: row['byName']?.toString() ?? '',
      );
    }).toList();
  }

  static int _readPrice(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class OrderEvent {
  const OrderEvent({
    required this.status,
    required this.at,
    required this.byName,
    required this.byRole,
  });

  final String status;
  final String at;
  final String byName;
  final String byRole;
}

class OrderReport {
  const OrderReport({
    required this.note,
    required this.image,
    required this.at,
    required this.byName,
  });

  final String note;
  final String image;
  final String at;
  final String byName;
}
