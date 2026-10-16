// End-to-end customer journey against a backend on this machine.
//
// Needs the backend running on :5001 with the demo customer seeded
// (demo@example.com / demo123 with one finished booking). See
// docs/APP_REBUILD_NOTES.md, "How the app was tested".
//
//   flutter test integration_test/customer_journey_test.dart -d <simulator>
//
// Lines starting with SHOT: mark screens worth a screenshot.
import 'dart:io';

import 'package:car_clean_user/main.dart';
import 'package:car_clean_user/src/config.dart';
import 'package:car_clean_user/src/services/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('customer books, tracks, moves, cancels, rates and chats', (tester) async {
    AppConfig.apiBase = Platform.isAndroid ? 'http://10.0.2.2:5001/api' : 'http://localhost:5001/api';
    SharedPreferences.setMockInitialValues({'ccp_walkthrough_seen': true});
    final store = await LocalStore.open();

    Future<void> idle([int ms = 600]) async {
      for (var i = 0; i < ms ~/ 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> waitFor(Finder finder, {int seconds = 15}) async {
      for (var i = 0; i < seconds * 10; i++) {
        if (finder.evaluate().isNotEmpty) return;
        await tester.pump(const Duration(milliseconds: 100));
      }
      throw TestFailure('Timed out waiting for $finder');
    }

    Future<void> shot(String name) async {
      // ignore: avoid_print
      print('SHOT:$name');
      await idle(2500);
    }

    Future<void> tapText(String text, {bool last = false}) async {
      final finder = last ? find.text(text).last : find.text(text).first;
      await waitFor(finder);
      await tester.ensureVisible(finder);
      await idle(300);
      await tester.tap(finder);
      await idle();
    }

    Future<void> type(String label, String value) async {
      final field = find.widgetWithText(TextField, label);
      await waitFor(field);
      await tester.ensureVisible(field.first);
      await tester.enterText(field.first, value);
      await idle(300);
    }

    await tester.pumpWidget(CarCleanApp(store: store));
    await waitFor(find.text('Popular services'));
    await shot('home_guest');

    // Sign in from the Profile tab.
    await tapText('Profile');
    await tapText('Sign in');
    await type('Email', 'demo@example.com');
    await type('Password', 'demo123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await waitFor(find.text('Priya Sharma'));
    await shot('profile_signed_in');

    // Add a vehicle from the home chip.
    await tapText('Home');
    await tapText('Add vehicle');
    await waitFor(find.text('Add your vehicle'));
    await tester.enterText(find.widgetWithText(TextField, 'Search model, e.g. Creta'), 'Creta');
    await idle();
    await tapText('Hyundai Creta');
    await shot('add_vehicle');
    await tapText('Save vehicle');
    await waitFor(find.text('Creta'));
    await shot('home_with_vehicle');

    // Book the Smart Wash.
    final book = find.widgetWithText(FilledButton, 'Book').first;
    await tester.scrollUntilVisible(book, 300, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await idle();
    await tester.tap(book);
    await waitFor(find.text('Checkout'));

    await tapText('Add the parking address');
    await waitFor(find.text('Add address'));
    await type('Full address', 'Flat 402, Shalimar Towers, Gomti Nagar');
    await tapText('Save address');
    await waitFor(find.text('Flat 402, Shalimar Towers, Gomti Nagar, Lucknow'));

    await tapText('10:00 AM');
    await waitFor(find.text('Bill details'));
    await tester.ensureVisible(find.text('Bill details'));
    await waitFor(find.text('Prices include GST.'));
    await shot('checkout_bill');

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm booking'));
    await waitFor(find.text('Booking Confirmed'), seconds: 20);
    await shot('booking_confirmed');

    // Track it.
    await tapText('Track order');
    await waitFor(find.text('Service details'));
    await shot('booking_tracking');

    // Move it to 01:30 PM.
    await tapText('Reschedule');
    await waitFor(find.text('Pick a new time'));
    await tapText('01:30 PM', last: true);
    await tapText('Move booking');
    await waitFor(find.textContaining('Moved to'));
    await idle(1500);

    // Cancel it.
    await tapText('Cancel booking');
    await waitFor(find.text('Cancel this booking?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
    await waitFor(find.text('Booking cancelled'));
    await shot('booking_cancelled');

    // Chat with the desk about it.
    await tester.tap(find.byTooltip('Chat with us'));
    await waitFor(find.text('Support chat'));
    await tester.enterText(find.byType(TextField), 'Sorry, plans changed. Will book again next week.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await waitFor(find.text('Sorry, plans changed. Will book again next week.'));
    await shot('chat');
    await tester.pageBack();
    await idle();
    await tester.pageBack();
    await idle();

    // Rate the finished wash from the Bookings tab.
    await tapText('Bookings');
    await tapText('Completed');
    await tapText('Rate this wash');
    await waitFor(find.text('How was your wash?'));
    await tester.ensureVisible(find.text('How was your wash?'));
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await idle();
    await tester.enterText(find.widgetWithText(TextField, 'Tell us what went well or what we can do better'), 'Spotless, thank you!');
    await tapText('Submit rating');
    await waitFor(find.text('Thanks for rating the wash'));
    await shot('rated');
    await tester.pageBack();
    await idle();

    await shot('bookings_tab');

    // Buying a plan needs Razorpay; the local server has no keys.
    await tapText('Plus');
    await waitFor(find.text('Choose a plan'));
    await shot('plus');
    await tester.tap(find.widgetWithText(FilledButton, 'Buy').first);
    await waitFor(find.text('Online payment is not configured on the server'));

    expect(store.token, isNotEmpty);
  });
}
