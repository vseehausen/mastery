import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/import_result.dart';
import '../../data/models/import_source.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

/// State for the import process
sealed class ImportState {
  const ImportState();
}

class ImportInitial extends ImportState {
  const ImportInitial();
}

class ImportPicking extends ImportState {
  const ImportPicking();
}

class ImportInProgress extends ImportState {
  final String filename;
  const ImportInProgress(this.filename);
}

class ImportSuccess extends ImportState {
  final ImportResult result;
  const ImportSuccess(this.result);
}

class ImportError extends ImportState {
  final String message;
  const ImportError(this.message);
}

/// Controller for the import flow
class ImportController extends StateNotifier<ImportState> {
  final Ref _ref;

  ImportController(this._ref) : super(const ImportInitial());

  /// Pick a file and import it
  Future<void> pickAndImport() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const ImportError('Please sign in to import highlights');
      return;
    }

    state = const ImportPicking();

    try {
      // Pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        state = const ImportInitial();
        return;
      }

      final file = result.files.first;
      final filename = file.name;

      state = ImportInProgress(filename);

      // Read file content
      String content;
      if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else {
        state = const ImportError('Could not read file content');
        return;
      }

      // Import the content
      final importService = _ref.read(importServiceProvider);
      final importResult = await importService.importFromContent(
        userId: userId,
        content: content,
        source: ImportSource.file,
        filename: filename,
      );

      state = ImportSuccess(importResult);
    } catch (e) {
      state = ImportError('Import failed: ${e.toString()}');
    }
  }

  /// Reset to initial state
  void reset() {
    state = const ImportInitial();
  }
}

/// Provider for ImportController
final importControllerProvider =
    StateNotifierProvider<ImportController, ImportState>((ref) {
  return ImportController(ref);
});
