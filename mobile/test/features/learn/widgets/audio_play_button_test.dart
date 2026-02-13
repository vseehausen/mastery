import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/audio_play_button.dart';

void main() {
  group('AudioPlayButton', () {
    testWidgets('renders nothing when audioUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioPlayButton(audioUrl: null, onPlay: null),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('renders icon button when audioUrl is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioPlayButton(
              audioUrl: 'https://example.com/word.mp3',
              onPlay: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('fires onPlay callback on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioPlayButton(
              audioUrl: 'https://example.com/word.mp3',
              onPlay: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.volume_up));
      expect(tapped, isTrue);
    });
  });
}
