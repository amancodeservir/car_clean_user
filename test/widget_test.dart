import 'package:car_clean_user/main.dart';
import 'package:car_clean_user/src/data/defaults.dart';
import 'package:car_clean_user/src/models/booking.dart';
import 'package:car_clean_user/src/models/catalog.dart';
import 'package:car_clean_user/src/services/local_store.dart';
import 'package:car_clean_user/src/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Booking _booking(String status, {String payment = ''}) => Booking(
      id: '665f1c2b9a7e4d0012abcd34',
      service: 'Basic Wash',
      vehicleName: 'Hyundai Creta',
      category: 'Large',
      city: 'Lucknow',
      address: '12 Hazratganj Main Road',
      date: '2026-10-20',
      timeSlot: 'Slot 2 – 10:00 AM',
      price: 499,
      status: status,
      paymentStatus: payment,
    );

void main() {
  group('formatting', () {
    test('rupees use Indian grouping', () {
      expect(rupees(499), '₹499');
      expect(rupees(1499), '₹1,499');
      expect(rupees(1234567), '₹12,34,567');
    });

    test('price tag only shows a discount when there is one', () {
      expect(const PriceTag(249, 249).hasDiscount, isFalse);
      expect(const PriceTag(249, 498).percentOff, 50);
      expect(const PriceTag(0).isKnown, isFalse);
    });
  });

  group('booking rules match the backend', () {
    test('cancel and reschedule only before a washer accepts', () {
      expect(_booking('pending').canCancel, isTrue);
      expect(_booking('confirmed').canCancel, isTrue);
      expect(_booking('accepted').canCancel, isFalse);
      expect(_booking('on_the_way').canReschedule, isFalse);
    });

    test('pay only unpaid live or finished bookings', () {
      expect(_booking('pending').canPay, isTrue);
      expect(_booking('completed').canPay, isTrue);
      expect(_booking('completed', payment: 'paid').canPay, isFalse);
      expect(_booking('cancelled').canPay, isFalse);
    });

    test('short id and slot time', () {
      final booking = _booking('pending');
      expect(booking.shortId, 'CCP-ABCD34');
      expect(booking.slotTime, '10:00 AM');
      expect(Booking.fromJson(booking.toJson()).vehicleName, 'Hyundai Creta');
    });

    test('slot ids are exactly what the backend accepts', () {
      expect(Defaults.slots.map((slot) => slot.id), contains('Slot 4 – 01:30 PM'));
      expect(Defaults.slots.length, 6);
    });
  });

  group('app', () {
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1170, 2532);
      view.devicePixelRatio = 3;
    });

    testWidgets('first launch shows the tour, then home as a guest', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await LocalStore.open();
      await tester.pumpWidget(CarCleanApp(store: store));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

      expect(find.text('Lucknow'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Popular services'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Smart Wash'), findsWidgets);
      expect(store.tourSeen, isTrue);
    });

    testWidgets('a guest who taps Book is sent to sign in', (tester) async {
      SharedPreferences.setMockInitialValues({'ccp_walkthrough_seen': true});
      final store = await LocalStore.open();
      await tester.pumpWidget(CarCleanApp(store: store));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

      await tester.scrollUntilVisible(find.widgetWithText(FilledButton, 'Book').first, 300, scrollable: find.byType(Scrollable).first);
      final book = find.widgetWithText(FilledButton, 'Book').first;
      await tester.ensureVisible(book);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(book);
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to continue your booking'), findsOneWidget);
    });
  });
}
