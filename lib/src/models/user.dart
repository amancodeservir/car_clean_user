import 'address.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    this.phone = '',
    this.city = '',
    this.address = '',
    this.role = 'customer',
    this.referralCode = '',
    this.credit = 0,
    this.planName = '',
    this.planWashesLeft = 0,
    this.seenOnboarding = false,
    this.addresses = const [],
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String role;
  final String referralCode;
  final int credit;
  final String planName;
  final int planWashesLeft;
  final bool seenOnboarding;
  final List<SavedAddress> addresses;
  final String token;

  bool get isCustomer => role == 'customer';

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initial => name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();

  factory AppUser.fromJson(Map<String, dynamic> json, String token) {
    final rows = json['addresses'];
    return AppUser(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      city: '${json['city'] ?? ''}',
      address: '${json['address'] ?? ''}',
      role: '${json['role'] ?? 'customer'}',
      referralCode: '${json['referralCode'] ?? ''}',
      credit: _int(json['credit']),
      planName: '${json['planName'] ?? ''}',
      planWashesLeft: _int(json['planWashesLeft']),
      seenOnboarding: json['seenOnboarding'] == true,
      addresses: rows is List
          ? rows.whereType<Map>().map((row) => SavedAddress.fromJson(Map<String, dynamic>.from(row))).toList()
          : const [],
      token: token,
    );
  }
}

int _int(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}
