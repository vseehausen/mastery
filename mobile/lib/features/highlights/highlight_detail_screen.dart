import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database/database.dart';
import '../../providers/database_provider.dart';
import '../books/books_provider.dart';
import 'highlight_edit_screen.dart';

/// Screen showing full details of a single highlight
class HighlightDetailScreen extends ConsumerWidget {
  final Highlight highlight;

  const HighlightDetailScreen({super.key, required this.highlight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(highlight.bookId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlight'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () => _copyToClipboard(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => _editHighlight(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book info
            bookAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (book) => book != null
                  ? _buildBookInfo(book)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Highlight type badge
            _buildTypeBadge(),
            const SizedBox(height: 16),

            // Content
            SelectableText(
              highlight.content,
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
              ),
            ),

            // Note (if exists)
            if (highlight.note != null && highlight.note!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNoteSection(),
            ],

            const SizedBox(height: 24),

            // Metadata
            _buildMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookInfo(Book book) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.book, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (book.author != null)
                  Text(
                    book.author!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isNote = highlight.type == 'note';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNote ? Colors.orange.shade100 : Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNote ? Icons.note : Icons.format_quote,
            size: 16,
            color: isNote ? Colors.orange.shade700 : Colors.deepPurple.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isNote ? 'Note' : 'Highlight',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNote ? Colors.orange.shade700 : Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personal Note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            highlight.note!,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        if (highlight.page != null) _buildMetadataRow('Page', '${highlight.page}'),
        if (highlight.location != null) _buildMetadataRow('Location', highlight.location!),
        if (highlight.kindleDate != null)
          _buildMetadataRow('Highlighted', dateFormat.format(highlight.kindleDate!)),
        _buildMetadataRow('Imported', dateFormat.format(highlight.createdAt)),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: highlight.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _editHighlight(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HighlightEditScreen(highlight: highlight),
      ),
    ).then((changed) {
      if (changed == true) {
        // Refresh the highlight data
        ref.invalidate(bookByIdProvider(highlight.bookId));
      }
    });
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'delete') {
      _showDeleteConfirmation(context, ref);
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Highlight'),
        content: const Text('Are you sure you want to delete this highlight?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final highlightRepo = ref.read(highlightRepositoryProvider);
                await highlightRepo.softDelete(highlight.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Highlight deleted')),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
