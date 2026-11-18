import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';

class SourceChips extends StatelessWidget {
  const SourceChips({super.key, required this.sources, this.limit});

  final List<SourceRef> sources;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final shown = limit == null ? sources : sources.take(limit!).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < shown.length; i++)
          ActionChip(
            label: Text(
              shown[i].host.isEmpty ? 'Source ${i + 1}' : shown[i].host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            avatar: CircleAvatar(
              radius: 9,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                '${i + 1}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            onPressed: () => showSourceSheet(context, shown[i]),
          ),
      ],
    );
  }
}

Future<void> showSourceSheet(BuildContext context, SourceRef source) async {
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.host.isEmpty ? 'Source' : source.host,
                style: textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 4),
              SelectableText(source.title, style: textTheme.titleMedium),
              if (source.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      source.content,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              if (source.url.isNotEmpty) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => launchExternal(sheetContext, source.url),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in browser'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Future<void> launchExternal(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && messenger != null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the link.')),
    );
  }
}
