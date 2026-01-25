// Basic Flutter widget test for Mastery app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mastery/main.dart';

void main() {
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MasteryApp()));

    // Verify the app shows the welcome message
    expect(find.text('Welcome to Mastery'), findsOneWidget);
    expect(find.text('Your vocabulary learning companion'), findsOneWidget);

    // Verify the import button is visible
    expect(find.text('Import Highlights'), findsOneWidget);
  });

  testWidgets('Bottom navigation is present', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasteryApp()));

    // Verify navigation destinations exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}
