import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'import_controller.dart';

/// Screen for importing Kindle clippings
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Highlights'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(context, ref, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ImportState state) {
    return switch (state) {
      ImportInitial() => _buildInitialState(context, ref),
      ImportPicking() => _buildPickingState(),
      ImportInProgress(:final filename) => _buildProgressState(filename),
      ImportSuccess(:final result) => _buildSuccessState(context, ref, result),
      ImportError(:final message) => _buildErrorState(context, ref, message),
    };
  }

  Widget _buildInitialState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.file_upload_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Import Your Kindle Highlights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your "My Clippings.txt" file from your Kindle device',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              ref.read(importControllerProvider.notifier).pickAndImport();
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Widget _buildPickingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Opening file picker...'),
        ],
      ),
    );
  }

  Widget _buildProgressState(String filename) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Importing $filename...'),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(
      BuildContext context, WidgetRef ref, result) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Import Complete!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatCard('Total Found', result.totalFound),
          _buildStatCard('Imported', result.imported, color: Colors.green),
          _buildStatCard('Skipped (Duplicates)', result.skipped,
              color: Colors.orange),
          if (result.errors > 0)
            _buildStatCard('Errors', result.errors, color: Colors.red),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  ref.read(importControllerProvider.notifier).reset();
                },
                child: const Text('Import More'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Text(
            'Import Failed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(importControllerProvider.notifier).reset();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
