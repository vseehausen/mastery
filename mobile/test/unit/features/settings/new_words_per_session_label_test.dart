import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/settings/presentation/screens/settings_screen.dart';

void main() {
  group('newWordsPerSessionLabelFor', () {
    test('returns Few for 3', () {
      expect(newWordsPerSessionLabelFor(3), 'Few');
    });

    test('returns Normal for 5', () {
      expect(newWordsPerSessionLabelFor(5), 'Normal');
    });

    test('returns Many for 8', () {
      expect(newWordsPerSessionLabelFor(8), 'Many');
    });
  });
}
