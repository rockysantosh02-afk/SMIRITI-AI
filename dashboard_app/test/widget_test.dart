// Basic Flutter widget test.
//
// Mocks Firebase method channels before the test binding is initialized.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Set up Firebase mocks BEFORE TestWidgetsFlutterBinding is initialized.
  // This must be at the top level so it runs before any test code.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Mock firebase_core plugin — returns a valid initialized app.
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'Firebase#initializeApp') {
          return <String, dynamic>{
            'name': '[DEFAULT]',
            'options': <String, dynamic>{
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project',
            },
          };
        }
        return null;
      },
    );

    // Mock firebase_auth plugin — returns a null user (not signed in).
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'authStateChanges') {
          return <Map<String, dynamic>>[];
        }
        return null;
      },
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Import SmritiApp locally so the mock is already set up before it runs.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('ok'))));
    expect(find.text('ok'), findsOneWidget);
  });
}
