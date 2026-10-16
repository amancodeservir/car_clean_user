/// Build-time settings. Override with `--dart-define=NAME=value`.
class AppConfig {
  /// Not const so the local test entry (test_driver/local_app.dart) can
  /// point the app at a backend on this machine.
  static String apiBase = const String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://carcleanplus-backend.vercel.app/api',
  );

  /// Public website, used for the privacy policy and terms links.
  /// Links are hidden while this is empty.
  static const siteBase = String.fromEnvironment('SITE_BASE');

  static const supportPhone = '+919120759988';
  static const supportPhoneLabel = '+91 91207 59988';
  static const supportEmail = 'carcleanplusofficial@gmail.com';
  static const supportWhatsApp = '919120759988';

  static const appName = 'Car Clean Plus';
}

/// Image assets shipped with the app.
class Photos {
  static const logo = 'assets/logo.jpeg';
  static const hero = 'assets/photos/hero.jpg';
  static const basic = 'assets/photos/basic_wash.jpg';
  static const premium = 'assets/photos/premium_wash.jpg';
  static const complete = 'assets/photos/complete_clean.jpg';
  static const waterless = 'assets/photos/waterless.jpg';
  static const interior = 'assets/photos/interior.jpg';
  static const dashboard = 'assets/photos/dashboard.jpg';
  static const engine = 'assets/photos/engine.jpg';
  static const tyre = 'assets/photos/tyre.jpg';
  static const seats = 'assets/photos/seats.jpg';
  static const promo = 'assets/photos/promo.jpg';
  static const beforeAfter = 'assets/photos/before_after.jpg';
  static const booking = 'assets/photos/booking.jpg';
  static const crew = 'assets/photos/crew.jpeg';
  static const walkthrough = 'assets/photos/walkthrough.jpg';
  static const carWash = 'assets/car_wash.jpg';
  static const bookWash = 'assets/book_wash.jpg';

  static String forService(String service) {
    switch (service) {
      case 'Basic Wash':
        return basic;
      case 'Premium Wash':
        return premium;
      case 'Complete Clean':
        return complete;
      case 'Festive Offer':
        return dashboard;
      case 'Waterless Wash':
        return waterless;
      default:
        return hero;
    }
  }

  static List<String> galleryFor(String service) {
    switch (service) {
      case 'Basic Wash':
        return [basic, tyre, beforeAfter];
      case 'Premium Wash':
        return [premium, interior, tyre];
      case 'Complete Clean':
        return [complete, seats, interior, dashboard];
      case 'Festive Offer':
        return [dashboard, engine, promo];
      case 'Waterless Wash':
        return [waterless, crew, basic];
      default:
        return [hero];
    }
  }

  static const cityImages = {
    'Mumbai': 'assets/mumbai.png',
    'Ahmedabad': 'assets/ahmedabad.png',
    'Hyderabad': 'assets/hyderabad.png',
    'Pune': 'assets/pune.png',
    'Chennai': 'assets/chennai.png',
    'Bengaluru': 'assets/bengaluru.png',
    'Nagpur': 'assets/nagpur.png',
    'New Delhi': 'assets/newdelhi.png',
  };
}
