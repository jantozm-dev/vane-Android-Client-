import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/models.dart';
import 'sources.dart';

class AnswerMarkdown extends StatelessWidget {
  const AnswerMarkdown({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MarkdownBody(
      data: data,
      softLineBreak: true,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href == null || href.isEmpty) return;
        showSourceSheet(
          context,
          SourceRef(title: text.isNotEmpty ? text : href, url: href),
        );
      },
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyLarge,
        h1: Theme.of(context).textTheme.headlineSmall,
        h2: Theme.of(context).textTheme.titleLarge,
        h3: Theme.of(context).textTheme.titleMedium,
        listBullet: Theme.of(context).textTheme.bodyLarge,
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: scheme.primary, width: 3)),
          color: scheme.surfaceContainerLow,
        ),
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
      ),
    );
  }
}
