// End-to-end customer journey on a simulator, against a backend on this
// machine (never the live API):
//
//   node serve.js /path/to/backend        # in-memory DB, see docs/APP_REBUILD_NOTES.md
//   flutter test integration_test/app_flow_test.dart -d <simulator id>
//
// Lines starting with `SHOT:` mark screens worth a screenshot.
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

  Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 15}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> settle(WidgetTester tester, [int ms = 900]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester, 600);
    // ignore: avoid_print
    print('SHOT:$name');
    await settle(tester, 2500);
  }

  Future<void> tapText(WidgetTester tester, String text, {Type? within}) async {
    final all = within == null ? find.text(text) : find.widgetWithText(within, text);
    try {
      await waitFor(tester, all, seconds: 4);
    } on TestFailure {
      // Below the part of the list that is built: scroll down to it.
      await tester.scrollUntilVisible(all, 250, scrollable: find.byType(Scrollable).hitTestable().first);
    }
    final finder = all.last;
    await tester.ensureVisible(finder);
    await settle(tester, 300);
    await tester.tap(finder, warnIfMissed: false);
    await settle(tester);
  }

  Future<void> type(WidgetTester tester, String label, String value) async {
    final field = find.widgetWithText(TextField, label).last;
    await waitFor(tester, field);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await settle(tester, 300);
  }

  testWidgets('customer books, tracks, moves, cancels and rates a wash', (tester) async {
    AppConfig.apiBase = Platform.isAndroid ? 'http://10.0.2.2:5001/api' : 'http://localhost:5001/api';
    SharedPreferences.setMockInitialValues({'ccp_walkthrough_seen': true});
    final store = await LocalStore.open();
    await tester.pumpWidget(CarCleanApp(store: store));
    await waitFor(tester, find.text('Popular services'));
    await shot(tester, 'home_guest');

    // Sign in from Profile.
    await tapText(tester, 'Profile');
    await tapText(tester, 'Sign in', within: FilledButton);
    await type(tester, 'Email', 'demo@example.com');
    await type(tester, 'Password', 'demo123');
    await shot(tester, 'login_filled');
    await tapText(tester, 'Sign in', within: FilledButton);
    await shot(tester, 'login_after');
    await waitFor(tester, find.text('Priya Sharma'));
    await shot(tester, 'profile');

    // Add a vehicle from the home chip.
    await tapText(tester, 'Home');
    await tapText(tester, 'Add vehicle');
    await type(tester, 'Search model, e.g. Creta', 'Creta');
    await tapText(tester, 'Hyundai Creta');
    await tapText(tester, 'Save vehicle');
    await waitFor(tester, find.text('Creta'));
    await shot(tester, 'home_with_vehicle');

    // Book the Smart Wash.
    await tapText(tester, 'Book', within: FilledButton);
    await waitFor(tester, find.text('Checkout'));
    await tapText(tester, 'Add the parking address');
    await type(tester, 'Full address', 'Flat 402, Shalimar Towers, Gomti Nagar');
    await tapText(tester, 'Save address');
    await waitFor(tester, find.text('Flat 402, Shalimar Towers, Gomti Nagar, Lucknow'));
    await tapText(tester, '10:00 AM');
    await tapText(tester, 'Wax  +₹149');
    await waitFor(tester, find.text('Bill details'));
    await shot(tester, 'checkout');
    await tapText(tester, 'Confirm booking');
    await waitFor(tester, find.text('Booking Confirmed'));
    await shot(tester, 'confirmed');

    // Track it.
    await tapText(tester, 'Track order');
    await waitFor(tester, find.text('Washer assigned'));
    await shot(tester, 'tracking');

    // Move it to another slot.
    await tapText(tester, 'Reschedule');
    await waitFor(tester, find.text('Pick a new time'));
    await tapText(tester, '01:30 PM');
    await tapText(tester, 'Move booking');
    await waitFor(tester, find.textContaining('01:30 PM'));

    // Chat with the desk.
    await tapText(tester, 'Chat with us');
    await waitFor(tester, find.text('Support chat'));
    await type(tester, 'Type a message', 'Please call when you reach the gate');
    await settle(tester, 1500); // let the keyboard finish moving the layout
    await tester.tap(find.byTooltip('Send'));
    // The bubble, not the text still in the input.
    await waitFor(tester, find.descendant(of: find.byType(ListView), matching: find.text('Please call when you reach the gate')));
    await shot(tester, 'chat');
    await tester.pageBack();
    await settle(tester);

    // Cancel it.
    await tapText(tester, 'Cancel booking', within: TextButton);
    await waitFor(tester, find.text('Cancel this booking?'));
    await tapText(tester, 'Plans changed');
    await tapText(tester, 'Cancel booking', within: FilledButton);
    await waitFor(tester, find.text('Booking cancelled'));
    await shot(tester, 'cancelled');
    await tester.pageBack();
    await settle(tester);

    // Rate the finished wash that the seed created.
    await tapText(tester, 'Bookings');
    await waitFor(tester, find.text('My Bookings'));
    await shot(tester, 'bookings');
    await tapText(tester, 'Completed');
    await tapText(tester, 'Premium Wash');
    await waitFor(tester, find.text('How was your wash?'));
    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await settle(tester);
    await tapText(tester, 'Submit rating');
    await waitFor(tester, find.text('Your rating'));
    await tester.pageBack();
    await settle(tester);

    // A plan cannot be bought for free any more.
    await tapText(tester, 'Plus');
    await waitFor(tester, find.text('Choose a plan'));
    await shot(tester, 'plus');
    await tapText(tester, 'Buy', within: FilledButton);
    await waitFor(tester, find.text('Online payment is not configured on the server'));
  });
}
