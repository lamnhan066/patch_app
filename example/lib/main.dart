import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patch_app/patch_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() {
  runApp(MaterialApp(home: _Home()));
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final patchApp = PatchApp(
    // Override updater so the example always shows the dialog flow.
    updater: _DemoUpdater(),
    confirmDialog: (context) => patchAppConfirmationDialog(context: context),
    minInterval: const Duration(minutes: 5), // throttle repeated checks
    debug: true,
    onError: (error, stack) => debugPrint('Update failed: $error'),
  );

  PatchResult? lastResult;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    // Case 1: auto-check on start & resume.
    patchApp.register(context: context);
  }

  @override
  void dispose() {
    patchApp.unregister();
    super.dispose();
  }

  Future<void> _runCheck(BuildContext context) async {
    setState(() => isChecking = true);
    final result = await patchApp.checkAndUpdate(context);
    if (!mounted || !context.mounted) return;
    setState(() {
      lastResult = result;
      isChecking = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Patch result: ${result.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('patch_app example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Auto-check on start/resume + manual checks with PatchResult feedback.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isChecking ? null : () => _runCheck(context),
              child: Text(isChecking ? 'Checking…' : 'Manual check & update'),
            ),
            const SizedBox(height: 16),
            Center(child: Text('Last result: ${lastResult?.name ?? 'none'}')),
          ],
        ),
      ),
    );
  }
}

/// Demo updater that always reports a pending restart, allowing the example
/// to surface the confirmation dialog without needing a real backend.
class _DemoUpdater implements ShorebirdUpdater {
  @override
  bool get isAvailable => true;

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async {
    return UpdateStatus.restartRequired;
  }

  @override
  Future<void> update({UpdateTrack? track}) async {}

  @override
  Future<Patch?> readCurrentPatch() async => null;

  @override
  Future<Patch?> readNextPatch() async => null;
}
