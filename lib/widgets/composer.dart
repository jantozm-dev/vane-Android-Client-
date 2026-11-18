import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.state,
    required this.controller,
    required this.onSubmit,
  });

  final VaneAppState state;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChanged);
      widget.controller.addListener(_handleChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final canSend =
        widget.controller.text.trim().isNotEmpty && !widget.state.isStreaming;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Ask anything…',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ListenableBuilder(
              listenable: widget.state,
              builder: (context, _) {
                if (widget.state.isStreaming) {
                  return IconButton.filledTonal(
                    onPressed: widget.state.cancel,
                    icon: const Icon(Icons.stop_rounded),
                    tooltip: 'Stop generating',
                  );
                }
                return IconButton.filled(
                  onPressed: canSend ? widget.onSubmit : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                  tooltip: 'Ask',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
