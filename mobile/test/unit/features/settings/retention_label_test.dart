import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/settings/presentation/screens/settings_screen.dart';

void main() {
  group('retentionLabelFor', () {
    test('returns Efficient at or below 0.85', () {
      expect(retentionLabelFor(0.85), 'Efficient');
      expect(retentionLabelFor(0.84), 'Efficient');
    });

    test('returns Balanced above 0.85 and up to 0.90', () {
      expect(retentionLabelFor(0.851), 'Balanced');
      expect(retentionLabelFor(0.90), 'Balanced');
      expect(retentionLabelFor(0.89), 'Balanced');
    });

    test('returns Reinforced above 0.90', () {
      expect(retentionLabelFor(0.901), 'Reinforced');
      expect(retentionLabelFor(0.93), 'Reinforced');
      expect(retentionLabelFor(0.95), 'Reinforced');
    });
  });
}
