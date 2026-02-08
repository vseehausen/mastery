import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/theme/app_theme.dart';
import 'features/learn/widgets/recall_card.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      theme: MasteryTheme.light,
      darkTheme: MasteryTheme.dark,
      home: const PreviewScreen(),
    );
  }
}

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use standard background, no gradient
      body: SafeArea(
        child: RecallCard(
          word: 'ephemeral',
          answer: 'vorübergehend, flüchtig',
          context: 'The beauty of cherry blossoms is ephemeral.',
          onGrade: (rating) {
            debugPrint('Graded: ');
          },
        ),
      ),
    );
  }
}
