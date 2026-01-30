// Basic Flutter widget test for Mastery app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mastery/main.dart';

void main() {
  testWidgets('App compiles and starts without crashing', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ProviderScope(child: MasteryApp()));

    // If we get here, the app compiled and started successfully
    // The AuthGuard may be loading auth state, which is normal
    expect(find.byType(Scaffold), findsWidgets);
  });
}
