import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:5001/api',
  );

  static const String bookedSlots = '/booking/booked-slots';
  static const String bookingLead = '/booking/lead';
  static const String myBookings = '/booking/mine';
  static const String catalog = '/catalog';
  static const String quote = '/catalog/quote';
  static const String vehicles = '/account/vehicles';
  static const String notifications = '/account/notifications';
  static const String plan = '/account/plan';
  static const String referral = '/account/referral';
  static const String otpRequest = '/auth/otp/request';
  static const String otpVerify = '/auth/otp/verify';

  static String booking(String id) => '/booking/$id';
  static String cancelBooking(String id) => '/booking/$id/cancel';
  static String rescheduleBooking(String id) => '/booking/$id/reschedule';
  static String rateBooking(String id) => '/booking/$id/rate';
  static String receiptBooking(String id) => '/booking/$id/receipt';
  static String bookingMessages(String id) => '/booking/$id/messages';
  static String reportBooking(String id) => '/booking/$id/report';
  static String vehicle(String id) => '/account/vehicles/$id';

  static const Color ink = Color(0xFF111827);
  static const Color paper = Color(0xFFF7F8FC);
  static const Color signal = Color(0xFF2563EB);
  static const Color mute = Color(0xFF6B7280);
  static const Color line = Color(0xFFE6E8EE);
  static const Color well = Color(0xFFE8EEFF);
  static const Color festival = Color(0xFFC2410C);
  static const Color festivalWash = Color(0xFFFFF7ED);
  static const Color orange = signal;
  static const Color cream = paper;
  static const String logo = 'assets/logo.jpeg';

  static const Color primaryColor = signal;
  static const Color accentColor = signal;
  static const double borderRadius = 16;
  static const double thinBorderWidth = 1;
  static const double iconSize = 22;

  static const String washPhoto = 'assets/car_wash.jpg';
  static const String bookWashPhoto = 'assets/book_wash.jpg';

  static const String photoBasic = 'assets/photos/basic_wash.png';
  static const String photoPremium = 'assets/photos/premium_wash.png';
  static const String photoComplete = 'assets/photos/complete_clean.png';
  static const String photoInterior = 'assets/photos/interior.png';
  static const String photoDashboard = 'assets/photos/dashboard.png';
  static const String photoTyre = 'assets/photos/tyre.png';
  static const String photoWaterless = 'assets/photos/waterless.png';
  static const String photoWalkthrough = 'assets/photos/walkthrough.jpg';
  static const String photoBooking = 'assets/photos/booking.png';
  static const String photoPromo = 'assets/photos/promo.png';
  static const String photoSeats = 'assets/photos/seats.png';
  static const String photoEngine = 'assets/photos/engine.png';
  static const String photoBeforeAfter = 'assets/photos/before_after.png';
  static const String photoHero = 'assets/photos/hero.png';
  static const String photoCrew = 'assets/photos/crew.jpeg';

  static String photoForOffer(String title) {
    switch (title) {
      case 'Foam Wash':
        return photoBasic;
      case 'Stream Wash':
        return photoPremium;
      case 'Polishing':
        return photoDashboard;
      case 'Deep Clean':
        return photoInterior;
      case 'Shine and Coat':
        return photoTyre;
      case 'Luxury Care':
        return photoEngine;
      default:
        return photoHero;
    }
  }

  static String photoForService(String service) {
    switch (service) {
      case 'Basic Wash':
        return photoBasic;
      case 'Premium Wash':
        return photoPremium;
      case 'Complete Clean':
        return photoComplete;
      case 'Festive Offer':
        return photoHero;
      case 'Waterless Wash':
        return photoWaterless;
      default:
        return photoPromo;
    }
  }

  static String galleryForService(String service) {
    switch (service) {
      case 'Basic Wash':
        return photoSeats;
      case 'Premium Wash':
        return photoTyre;
      case 'Complete Clean':
        return photoInterior;
      case 'Festive Offer':
        return photoBeforeAfter;
      case 'Waterless Wash':
        return photoCrew;
      default:
        return photoSeats;
    }
  }

  static String sheetForService(String service) {
    switch (service) {
      case 'Basic Wash':
        return photoBeforeAfter;
      case 'Premium Wash':
        return photoDashboard;
      case 'Complete Clean':
        return photoEngine;
      case 'Festive Offer':
        return photoPromo;
      case 'Waterless Wash':
        return photoBooking;
      default:
        return photoBooking;
    }
  }
}
