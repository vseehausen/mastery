import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/app_theme.dart';
import 'definition_cue_card.dart';
import 'recall_card.dart';
import 'synonym_cue_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PREVIEW ANNOTATION
// ═══════════════════════════════════════════════════════════════════════════

/// Custom preview that applies Mastery theme to all previews
final class MasteryPreview extends Preview {
  const MasteryPreview({
    super.name,
    super.group,
    super.brightness,
    super.size = const Size(400, 800),
  });
}

/// Multi-brightness preview for light and dark modes
final class MasteryBrightnessPreview extends MultiPreview {
  const MasteryBrightnessPreview({required this.name, required this.group});

  final String name;
  final String group;

  @override
  List<Preview> get previews => [
        MasteryPreview(
          name: '$name - Light',
          group: group,
          brightness: Brightness.light,
        ),
        MasteryPreview(
          name: '$name - Dark',
          group: group,
          brightness: Brightness.dark,
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
// RECALL CARD PREVIEWS
// ═══════════════════════════════════════════════════════════════════════════

@MasteryBrightnessPreview(
  name: 'Recall Card - Initial State',
  group: 'Recall Card',
)
Widget recallCardInitial() {
  return ShadApp(
    theme: MasteryTheme.light,
    darkTheme: MasteryTheme.dark,
    home: Scaffold(
      body: RecallCard(
        word: 'ephemeral',
        answer: 'vorübergehend, flüchtig',
        context: 'The beauty of cherry blossoms is ephemeral.',
        onGrade: (_) {},
      ),
    ),
  );
}

@MasteryBrightnessPreview(
  name: 'Recall Card - Revealed',
  group: 'Recall Card',
)
Widget recallCardRevealed() {
  return ShadApp(
    theme: MasteryTheme.light,
    darkTheme: MasteryTheme.dark,
    home: const Scaffold(
      body: _RecallCardRevealedWrapper(
        word: 'ephemeral',
        answer: 'vorübergehend, flüchtig',
        context: 'The beauty of cherry blossoms is ephemeral.',
      ),
    ),
  );
}

@MasteryPreview(
  name: 'Recall Card - No Context',
  group: 'Recall Card',
  brightness: Brightness.light,
)
Widget recallCardNoContext() {
  return ShadApp(
    theme: MasteryTheme.light,
    home: Scaffold(
      body: RecallCard(
        word: 'ubiquitous',
        answer: 'allgegenwärtig',
        onGrade: (_) {},
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SYNONYM CUE CARD PREVIEWS
// ═══════════════════════════════════════════════════════════════════════════

@MasteryBrightnessPreview(
  name: 'Synonym Cue - Initial State',
  group: 'Synonym Cue Card',
)
Widget synonymCueInitial() {
  return ShadApp(
    theme: MasteryTheme.light,
    darkTheme: MasteryTheme.dark,
    home: Scaffold(
      body: SynonymCueCard(
        synonymPhrase: 'lasting for a very short time',
        targetWord: 'ephemeral',
        onGrade: (_) {},
      ),
    ),
  );
}

@MasteryBrightnessPreview(
  name: 'Synonym Cue - Revealed',
  group: 'Synonym Cue Card',
)
Widget synonymCueRevealed() {
  return ShadApp(
    theme: MasteryTheme.light,
    darkTheme: MasteryTheme.dark,
    home: const Scaffold(
      body: _SynonymCueRevealedWrapper(
        synonymPhrase: 'lasting for a very short time',
        targetWord: 'ephemeral',
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// DEFINITION CUE CARD PREVIEWS
// ═══════════════════════════════════════════════════════════════════════════

@MasteryBrightnessPreview(
  name: 'Definition Cue - Initial State',
  group: 'Definition Cue Card',
)
Widget definitionCueInitial() {
  return ShadApp(
    theme: MasteryTheme.light,
    darkTheme: MasteryTheme.dark,
    home: Scaffold(
      body: DefinitionCueCard(
        definition: 'present, appearing, or found everywhere',
        targetWord: 'ubiquitous',
        hintText: 'Starts with "u"',
        onGrade: (_) {},
      ),
    ),
  );
}

@MasteryBrightnessPreview(
  name: 'Definition Cue - Revealed',
  group: 'Definition Cue Card',
)
Widget definitionCueRevealed() {
  return ShadApp(
    theme: MasteryTheme.light,
    darkTheme: MasteryTheme.dark,
    home: const Scaffold(
      body: _DefinitionCueRevealedWrapper(
        definition: 'present, appearing, or found everywhere',
        targetWord: 'ubiquitous',
        hintText: 'Starts with "u"',
      ),
    ),
  );
}

@MasteryPreview(
  name: 'Definition Cue - No Hint',
  group: 'Definition Cue Card',
  brightness: Brightness.light,
)
Widget definitionCueNoHint() {
  return ShadApp(
    theme: MasteryTheme.light,
    home: Scaffold(
      body: DefinitionCueCard(
        definition: 'feeling or showing anger or annoyance at what is perceived as unfair treatment',
        targetWord: 'indignant',
        onGrade: (_) {},
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// WRAPPER WIDGETS (to show revealed state)
// ═══════════════════════════════════════════════════════════════════════════

class _RecallCardRevealedWrapper extends StatefulWidget {
  const _RecallCardRevealedWrapper({
    required this.word,
    required this.answer,
    this.context,
  });

  final String word;
  final String answer;
  final String? context;

  @override
  State<_RecallCardRevealedWrapper> createState() =>
      _RecallCardRevealedWrapperState();
}

class _RecallCardRevealedWrapperState
    extends State<_RecallCardRevealedWrapper> {
  @override
  void initState() {
    super.initState();
    // Automatically reveal after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // Trigger a tap to reveal
          setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5), // Indigo 600
            Color(0xFF7C3AED), // Violet 600
            Color(0xFFDB2777), // Pink 600
          ],
        ),
      ),
      child: RecallCard(
        word: widget.word,
        answer: widget.answer,
        context: widget.context,
        onGrade: (_) {},
      ),
    );
  }
}

class _SynonymCueRevealedWrapper extends StatefulWidget {
  const _SynonymCueRevealedWrapper({
    required this.synonymPhrase,
    required this.targetWord,
  });

  final String synonymPhrase;
  final String targetWord;

  @override
  State<_SynonymCueRevealedWrapper> createState() =>
      _SynonymCueRevealedWrapperState();
}

class _SynonymCueRevealedWrapperState
    extends State<_SynonymCueRevealedWrapper> {
  @override
  Widget build(BuildContext context) {
    return SynonymCueCard(
      synonymPhrase: widget.synonymPhrase,
      targetWord: widget.targetWord,
      onGrade: (_) {},
    );
  }
}

class _DefinitionCueRevealedWrapper extends StatefulWidget {
  const _DefinitionCueRevealedWrapper({
    required this.definition,
    required this.targetWord,
    this.hintText,
  });

  final String definition;
  final String targetWord;
  final String? hintText;

  @override
  State<_DefinitionCueRevealedWrapper> createState() =>
      _DefinitionCueRevealedWrapperState();
}

class _DefinitionCueRevealedWrapperState
    extends State<_DefinitionCueRevealedWrapper> {
  @override
  Widget build(BuildContext context) {
    return DefinitionCueCard(
      definition: widget.definition,
      targetWord: widget.targetWord,
      hintText: widget.hintText,
      onGrade: (_) {},
    );
  }
}
