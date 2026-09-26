import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_management_frontend_mobile_app_flutter/main.dart';

void main() {
  testWidgets('Login screen shows role toggle and login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HostelManagementApp()),
    );

    expect(find.text('Hostel Management'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Hostel Admin'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
