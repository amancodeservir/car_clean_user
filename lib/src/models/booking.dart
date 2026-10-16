class Booking {
  const Booking({
    required this.id,
    required this.service,
    required this.vehicleName,
    required this.category,
    required this.city,
    required this.address,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.status,
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.paymentUrl = '',
    this.createdAt = '',
    this.instructions = '',
    this.mobile = '',
    this.washerName = '',
    this.washerPhone = '',
    this.discount = 0,
    this.travelFee = 0,
    this.creditUsed = 0,
    this.planUsed = false,
    this.addons = const [],
    this.rating,
    this.review = '',
    this.beforePhoto = '',
    this.afterPhoto = '',
    this.timeline = const [],
    this.reports = const [],
  });

  final String id;
  final String service;
  final String vehicleName;
  final String category;
  final String city;
  final String address;
  final String date;
  final String timeSlot;
  final int price;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentUrl;
  final String createdAt;
  final String instructions;
  final String mobile;
  final String washerName;
  final String washerPhone;
  final int discount;
  final int travelFee;
  final int creditUsed;
  final bool planUsed;
  final List<BookingAddon> addons;
  final int? rating;
  final String review;
  final String beforePhoto;
  final String afterPhoto;
  final List<BookingEvent> timeline;
  final List<BookingReport> reports;

  String get shortId => id.length <= 6 ? id.toUpperCase() : 'CCP-${id.substring(id.length - 6).toUpperCase()}';

  bool get isBike => category == 'Bike';
  bool get isCancelled => status == 'cancelled' || status == 'canceled';
  bool get isCompleted => status == 'completed';
  bool get isUpcoming => !isCancelled && !isCompleted && status != 'blocked' && status != 'lead';
  bool get isActive => status == 'accepted' || status == 'on_the_way' || status == 'in_progress';
  bool get isPaid => paymentStatus == 'paid';

  /// Same rules as the backend: before a washer accepts the job.
  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get canReschedule => status == 'pending' || status == 'confirmed';
  bool get canPay => !isPaid && price > 0 && (isUpcoming || isCompleted);
  bool get canRate => isCompleted && rating == null;

  String get statusLabel => labelFor(status);

  static String labelFor(String status) {
    switch (status) {
      case 'pending':
        return 'Booked';
      case 'confirmed':
        return 'Confirmed';
      case 'accepted':
        return 'Washer assigned';
      case 'on_the_way':
        return 'On the way';
      case 'in_progress':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        final clean = status.replaceAll('_', ' ').trim();
        return clean.isEmpty ? 'Update' : clean[0].toUpperCase() + clean.substring(1);
    }
  }

  /// The clock part of `Slot 2 – 10:00 AM`.
  String get slotTime {
    final parts = timeSlot.split(RegExp(r'\s[–-]\s'));
    return (parts.length > 1 ? parts.last : timeSlot).trim();
  }

  DateTime? get day => DateTime.tryParse(date);

  Map<String, dynamic> toJson() => {
        '_id': id,
        'service': service,
        'carModel': {'name': vehicleName, 'category': category},
        'location': {'city': city, 'address': address},
        'date': date,
        'timeSlot': timeSlot,
        'finalPrice': price,
        'status': status,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'paymentUrl': paymentUrl,
        'createdAt': createdAt,
        'washerName': washerName,
        'washerPhone': washerPhone,
        'discount': discount,
        'travelFee': travelFee,
        'creditUsed': creditUsed,
        'planUsed': planUsed,
        'addons': addons.map((addon) => {'name': addon.name, 'price': addon.price}).toList(),
        'rating': rating,
        'review': review,
        'timeline': timeline
            .map((event) => {
                  'status': event.status,
                  'at': event.at,
                  'byName': event.byName,
                  'byRole': event.byRole,
                  'note': event.note,
                })
            .toList(),
      };

  /// Reads the backend booking document.
  factory Booking.fromJson(Map<String, dynamic> json) {
    final car = _map(json['carModel']);
    final location = _map(json['location']);
    final customer = _map(json['customerDetails']);
    final staff = _map(json['assignedStaff']);
    final addons = json['addons'];
    final timeline = json['timeline'];
    final reports = json['reports'];
    final rating = json['rating'];
    return Booking(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      service: _text(json['service']),
      vehicleName: _text(car['name'] ?? json['vehicleName']),
      category: _text(car['category'] ?? json['category']),
      city: _text(location['city'] ?? json['city']),
      address: _text(location['address'] ?? json['address']),
      date: _text(json['date']),
      timeSlot: _text(json['timeSlot']),
      price: _int(json['finalPrice'] ?? json['price']),
      status: _text(json['status']),
      paymentMethod: _text(json['paymentMethod']),
      paymentStatus: _text(json['paymentStatus']),
      paymentUrl: _text(json['paymentUrl']),
      createdAt: _text(json['createdAt']),
      instructions: _text(customer['instructions']),
      mobile: _text(customer['mobile']),
      washerName: _text(json['washerName']).isNotEmpty ? _text(json['washerName']) : _text(staff['name']),
      washerPhone: _text(json['washerPhone']).isNotEmpty ? _text(json['washerPhone']) : _text(staff['phone']),
      discount: _int(json['discount']),
      travelFee: _int(json['travelFee']),
      creditUsed: _int(json['creditUsed']),
      planUsed: json['planUsed'] == true,
      addons: addons is List
          ? addons
              .whereType<Map>()
              .map((row) => BookingAddon(_text(row['name']), _int(row['price'])))
              .where((row) => row.name.isNotEmpty)
              .toList()
          : const [],
      rating: rating is num ? rating.round() : null,
      review: _text(json['review']),
      beforePhoto: _text(json['beforePhoto']),
      afterPhoto: _text(json['afterPhoto']),
      timeline: timeline is List
          ? timeline.whereType<Map>().map((row) {
              return BookingEvent(
                status: _text(row['status']),
                at: _text(row['at']),
                byName: _text(row['byName']),
                byRole: _text(row['byRole']),
                note: _text(row['note']),
              );
            }).toList()
          : const [],
      reports: reports is List
          ? reports.whereType<Map>().map((row) {
              return BookingReport(
                note: _text(row['note']),
                image: _text(row['image']),
                at: _text(row['at']),
                byName: _text(row['byName']),
              );
            }).toList()
          : const [],
    );
  }
}

class BookingAddon {
  const BookingAddon(this.name, this.price);
  final String name;
  final int price;
}

class BookingEvent {
  const BookingEvent({
    required this.status,
    required this.at,
    this.byName = '',
    this.byRole = '',
    this.note = '',
  });

  final String status;
  final String at;
  final String byName;
  final String byRole;
  final String note;
}

class BookingReport {
  const BookingReport({required this.note, required this.image, required this.at, required this.byName});

  final String note;
  final String image;
  final String at;
  final String byName;
}

class SupportMessage {
  const SupportMessage({required this.body, required this.fromRole, required this.at, required this.mine});

  final String body;
  final String fromRole;
  final String at;
  final bool mine;

  factory SupportMessage.fromJson(Map<String, dynamic> json, String myId) {
    return SupportMessage(
      body: _text(json['body']),
      fromRole: _text(json['fromRole']),
      at: _text(json['createdAt']),
      mine: _text(json['user']) == myId,
    );
  }
}

Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _text(dynamic value) => value == null ? '' : '$value'.trim();

int _int(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse('${value ?? ''}') ?? 0;
}
