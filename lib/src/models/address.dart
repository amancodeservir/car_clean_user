class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  bool get hasPin => latitude != null && longitude != null;

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      label: '${json['label'] ?? 'Home'}',
      address: '${json['address'] ?? ''}',
      city: '${json['city'] ?? ''}',
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      isDefault: json['isDefault'] == true,
    );
  }
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}
