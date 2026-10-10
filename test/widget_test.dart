import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:car_clean_user/main.dart';

void main() {
  testWidgets('Car Clean Plus is shown after auth loading',
      (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Car Clean Plus'), findsWidgets);
  });
}
