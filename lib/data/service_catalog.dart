class TimeSlot {
  final String id;
  final String label;
  final String timeKey;
  final String period;

  const TimeSlot({
    required this.id,
    required this.label,
    required this.timeKey,
    required this.period,
  });
}

class CarModelOption {
  final String name;
  final String category;

  const CarModelOption({
    required this.name,
    required this.category,
  });
}

class ServiceCatalog {
  static const List<TimeSlot> timeSlots = [
    TimeSlot(
      id: 'Slot 1 \u2013 08:30 AM',
      label: '08:30 AM',
      timeKey: '08:30',
      period: 'AM',
    ),
    TimeSlot(
      id: 'Slot 2 \u2013 10:00 AM',
      label: '10:00 AM',
      timeKey: '10:00',
      period: 'AM',
    ),
    TimeSlot(
      id: 'Slot 3 \u2013 11:30 AM',
      label: '11:30 AM',
      timeKey: '11:30',
      period: 'AM',
    ),
    TimeSlot(
      id: 'Slot 4 \u2013 01:30 PM',
      label: '01:30 PM',
      timeKey: '01:30',
      period: 'PM',
    ),
    TimeSlot(
      id: 'Slot 5 \u2013 03:00 PM',
      label: '03:00 PM',
      timeKey: '03:00',
      period: 'PM',
    ),
    TimeSlot(
      id: 'Slot 6 \u2013 04:30 PM',
      label: '04:30 PM',
      timeKey: '04:30',
      period: 'PM',
    ),
  ];

  static const List<String> carCategories = [
    'Compact',
    'Standard',
    'Large',
    'Premium Compact',
    'Premium Standard',
    'Premium Large',
    'Premium',
    'Bike',
  ];

  static const List<CarModelOption> carModels = [
    CarModelOption(name: 'Maruti Suzuki Alto', category: 'Compact'),
    CarModelOption(name: 'Maruti Suzuki WagonR', category: 'Compact'),
    CarModelOption(name: 'Maruti Suzuki Swift', category: 'Compact'),
    CarModelOption(name: 'Maruti Suzuki Celerio', category: 'Compact'),
    CarModelOption(name: 'Hyundai Grand i10', category: 'Compact'),
    CarModelOption(name: 'Tata Tiago', category: 'Compact'),
    CarModelOption(name: 'Renault Kwid', category: 'Compact'),
    CarModelOption(name: 'Maruti Suzuki Baleno', category: 'Standard'),
    CarModelOption(name: 'Maruti Suzuki Dzire', category: 'Standard'),
    CarModelOption(name: 'Maruti Suzuki Brezza', category: 'Standard'),
    CarModelOption(name: 'Hyundai i20', category: 'Standard'),
    CarModelOption(name: 'Honda Amaze', category: 'Standard'),
    CarModelOption(name: 'Honda City', category: 'Standard'),
    CarModelOption(name: 'Hyundai Venue', category: 'Standard'),
    CarModelOption(name: 'Tata Nexon', category: 'Standard'),
    CarModelOption(name: 'Hyundai Creta', category: 'Large'),
    CarModelOption(name: 'Kia Seltos', category: 'Large'),
    CarModelOption(name: 'Toyota Innova Crysta', category: 'Large'),
    CarModelOption(name: 'Toyota Fortuner', category: 'Large'),
    CarModelOption(name: 'Mahindra XUV700', category: 'Large'),
    CarModelOption(name: 'Mahindra Scorpio N', category: 'Large'),
    CarModelOption(name: 'Tata Harrier', category: 'Large'),
    CarModelOption(name: 'MG Hector', category: 'Large'),
    CarModelOption(name: 'Mercedes-Benz A-Class', category: 'Premium Compact'),
    CarModelOption(name: 'BMW 2 Series', category: 'Premium Compact'),
    CarModelOption(name: 'Mercedes-Benz C-Class', category: 'Premium Standard'),
    CarModelOption(name: 'BMW 3 Series', category: 'Premium Standard'),
    CarModelOption(name: 'Mercedes-Benz GLE', category: 'Premium Large'),
    CarModelOption(name: 'BMW X5', category: 'Premium Large'),
    CarModelOption(name: 'Mercedes-Benz S-Class', category: 'Premium'),
    CarModelOption(name: 'BMW 7 Series', category: 'Premium'),
  ];

  static const List<String> serviceNames = [
    'Basic Wash',
    'Premium Wash',
    'Complete Clean',
    'Festive Offer',
    'Waterless Wash',
  ];

  static const Map<String, Map<String, int>> _prices = {
    'Compact': {
      'Basic Wash': 299,
      'Premium Wash': 499,
      'Complete Clean': 699,
      'Festive Offer': 899,
      'Waterless Wash': 349,
    },
    'Standard': {
      'Basic Wash': 399,
      'Premium Wash': 599,
      'Complete Clean': 799,
      'Festive Offer': 999,
      'Waterless Wash': 449,
    },
    'Large': {
      'Basic Wash': 499,
      'Premium Wash': 699,
      'Complete Clean': 899,
      'Festive Offer': 1199,
      'Waterless Wash': 549,
    },
    'Premium Compact': {
      'Basic Wash': 499,
      'Premium Wash': 699,
      'Complete Clean': 899,
      'Festive Offer': 1099,
      'Waterless Wash': 549,
    },
    'Premium Standard': {
      'Basic Wash': 599,
      'Premium Wash': 799,
      'Complete Clean': 999,
      'Festive Offer': 1299,
      'Waterless Wash': 649,
    },
    'Premium Large': {
      'Basic Wash': 699,
      'Premium Wash': 899,
      'Complete Clean': 1199,
      'Festive Offer': 1499,
      'Waterless Wash': 749,
    },
    'Premium': {
      'Basic Wash': 699,
      'Premium Wash': 899,
      'Complete Clean': 1199,
      'Festive Offer': 1499,
      'Waterless Wash': 749,
    },
    'Bike': {
      'Basic Wash': 149,
      'Premium Wash': 249,
      'Complete Clean': 349,
      'Festive Offer': 399,
      'Waterless Wash': 199,
    },
  };

  static int priceFor({required String category, required String service}) {
    return _prices[category]?[service] ?? 0;
  }

  /// True only when [ymdDate] is today and the current local time is at or
  /// after the slot start. PM hours are converted by adding 12, except 12.
  static bool isSlotPast(String ymdDate, TimeSlot slot) {
    final parts = ymdDate.split('-');
    if (parts.length != 3) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;

    final now = DateTime.now();
    if (now.year != year || now.month != month || now.day != day) {
      return false;
    }

    final timeParts = slot.timeKey.split(':');
    if (timeParts.length != 2) return false;
    var hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return false;

    final period = slot.period.toUpperCase();
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    final slotStart = DateTime(year, month, day, hour, minute);
    return !now.isBefore(slotStart);
  }

  /// True when any booked entry is ALL_DAY, or contains this slot id or label.
  static bool isSlotBooked(TimeSlot slot, List<String> booked) {
    final id = slot.id.toLowerCase();
    final label = slot.label.toLowerCase();
    for (final entry in booked) {
      final value = entry.toLowerCase();
      if (value.contains('all_day') ||
          value.contains(id) ||
          value.contains(label)) {
        return true;
      }
    }
    return false;
  }
}
