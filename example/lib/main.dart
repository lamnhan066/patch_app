import 'package:flutter/material.dart';
import 'package:patch_app/patch_app.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final patchApp = PatchApp(
    confirmDialog: (context) => patchAppConfirmationDialog(context: context),
    onError: (error, stack) => debugPrint('Update failed: $error'),
  );

  @override
  void initState() {
    super.initState();

    // Auto-checks on start & resume
    patchApp.register(context);
  }

  @override
  void dispose() {
    // Stops lifecycle listener
    patchApp.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      // Check and update manually
      onPressed: () => patchApp.checkAndUpdate(context),
      child: const Text('Check and Update'),
    );
  }
}
