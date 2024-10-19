import 'package:whereisthetoilet/models/user_models.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whereisthetoilet/main.dart';
import 'package:realm/realm.dart';

void main() {
  final config = Configuration.local(
    [
      UserModel.schema,
    ],
  );
  final realm = Realm(config);
  UserModel? userModel;
  final results = realm.all<UserModel>();
  if (results.isNotEmpty) {
    userModel = results.first;
  }
  final router = FluroRouter();
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      Main(
        realm: realm,
        userModel: userModel,
        router: router,
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
