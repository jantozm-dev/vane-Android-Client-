import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, required this.state});

  final VaneAppState state;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late final TextEditingController _url;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.state.settings.baseUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the address of your Vane instance.'),
        ),
      );
      return;
    }
    await widget.state.connect(serverUrl: url);
    if (widget.state.connection == ConnectionPhase.ready && mounted) {
      await widget.state.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final state = widget.state;
        if (state.connection == ConnectionPhase.loading ||
            state.connection == ConnectionPhase.connecting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Connecting to your Vane instance…',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        final isError = state.connection == ConnectionPhase.error;

        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isError
                          ? 'Could not connect'
                          : 'Connect to your Vane instance',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (isError && state.connectionError != null) ...[
                      Text(
                        state.connectionError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Run Vane with Docker, then enter the address of your '
                      'instance below. Use your computer\u2019s LAN IP '
                      '(e.g. 192.168.1.50:3000) so your phone can reach it.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      autofillHints: const [AutofillHints.url],
                      decoration: const InputDecoration(
                        labelText: 'Server address',
                        hintText: 'http://192.168.1.50:3000',
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                      onSubmitted: (_) => _connect(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _connect,
                      icon: const Icon(Icons.link),
                      label: const Text('Connect'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Self-hosted with Vane? Your queries never leave '
                      'your own hardware.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
