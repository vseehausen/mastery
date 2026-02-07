import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/network/connectivity.dart';
import 'package:mastery/core/widgets/global_status_banner.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('deriveGlobalStatusBannerData', () {
    test('returns offline status when disconnected', () {
      final data = deriveGlobalStatusBannerData(
        connectivity: ConnectivityStatus.disconnected,
        vocabularyCount: const AsyncValue<int>.data(10),
        enrichedVocabularyIds: const AsyncValue<Set<String>>.data(<String>{}),
      );

      expect(data, isNotNull);
      expect(data!.type, GlobalStatusType.offline);
    });

    test('returns sync error when data providers fail', () {
      final data = deriveGlobalStatusBannerData(
        connectivity: ConnectivityStatus.connected,
        vocabularyCount: AsyncValue<int>.error(
          Exception('boom'),
          StackTrace.empty,
        ),
        enrichedVocabularyIds: const AsyncValue<Set<String>>.data(<String>{}),
      );

      expect(data, isNotNull);
      expect(data!.type, GlobalStatusType.syncError);
    });

    test('returns null for enrichment progress when setting is disabled', () {
      final data = deriveGlobalStatusBannerData(
        connectivity: ConnectivityStatus.connected,
        vocabularyCount: const AsyncValue<int>.data(10),
        enrichedVocabularyIds: const AsyncValue<Set<String>>.data({
          'a',
          'b',
          'c',
        }),
      );

      expect(data, isNull);
    });

    test(
      'returns syncing state with progress when enrichment is incomplete',
      () {
        final data = deriveGlobalStatusBannerData(
          connectivity: ConnectivityStatus.connected,
          vocabularyCount: const AsyncValue<int>.data(10),
          showEnrichmentProgress: true,
          enrichedVocabularyIds: const AsyncValue<Set<String>>.data({
            'a',
            'b',
            'c',
            'd',
          }),
        );

        expect(data, isNotNull);
        expect(data!.type, GlobalStatusType.enrichmentProgress);
        expect(data.progress, closeTo(0.4, 0.001));
        expect(data.message, contains('Preparing enrichments'));
      },
    );

    test('returns null when sync is complete', () {
      final data = deriveGlobalStatusBannerData(
        connectivity: ConnectivityStatus.connected,
        vocabularyCount: const AsyncValue<int>.data(3),
        enrichedVocabularyIds: const AsyncValue<Set<String>>.data({
          'a',
          'b',
          'c',
        }),
      );

      expect(data, isNull);
    });
  });

  group('GlobalStatusBanner', () {
    testWidgets('renders message and action', (tester) async {
      await tester.pumpTestWidget(
        GlobalStatusBanner(
          data: const GlobalStatusBannerData(
            type: GlobalStatusType.offline,
            message: 'You are offline.',
          ),
          actionLabel: 'Retry',
          onActionPressed: () {},
        ),
      );

      expect(find.text('You are offline.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('shows progress bar for syncing state', (tester) async {
      await tester.pumpTestWidget(
        GlobalStatusBanner(
          data: const GlobalStatusBannerData(
            type: GlobalStatusType.enrichmentProgress,
            message: 'Preparing enrichments',
            progress: 0.7,
          ),
          actionLabel: 'Details',
          onActionPressed: () {},
        ),
      );

      expect(find.text('Preparing enrichments'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
