import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:patch_app/src/patch_result.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:terminate_restart/terminate_restart.dart';

/// A helper class that manages Shorebird code push updates and restarts.
///
/// This class simplifies the process of checking for app updates,
/// downloading them, and restarting the app when needed.
///
/// Typical usage:
/// ```dart
/// await PatchApp(
///   confirmDialog: (context) => patchAppConfirmationDialog(context: context),
/// ).checkAndUpdate(context);
/// ```
///
/// It supports configurable update intervals, error handling,
/// and debug logging for easier monitoring.
class PatchApp {
  /// Creates a new instance of [PatchApp].
  ///
  /// - [confirmDialog] is a callback that shows a dialog asking
  ///   whether the user agrees to restart after applying an update.
  /// - [minInterval] defines the minimum duration between update checks.
  ///   Defaults to 15 minutes.
  /// - [onError] handles any error that occurs during the update process.
  /// - [debug] enables debug logging if set to `true`.
  PatchApp({
    required this.confirmDialog,
    this.minInterval = const Duration(minutes: 15),
    this.onError,
    this.debug = false,
    ShorebirdUpdater? updater,
    TerminateRestart? terminateRestart,
    DateTime Function()? now,
  }) : _updater = updater ?? ShorebirdUpdater(),
       _terminateRestart = terminateRestart ?? TerminateRestart.instance,
       _now = now ?? DateTime.now;

  /// A callback to display a confirmation dialog before restarting the app.
  ///
  /// Must return `true` to proceed with the restart, or `false` to cancel.
  final Future<bool> Function(BuildContext context) confirmDialog;

  /// The minimum time interval between consecutive update checks.
  final Duration minInterval;

  /// A callback for handling errors during the update process.
  ///
  /// Receives the `error` and `stackTrace` when an exception occurs.
  final void Function(Object error, StackTrace stack)? onError;

  /// Enables or disables debug logging.
  ///
  /// When `true`, update logs are printed via [debugPrint].
  final bool debug;

  /// The underlying Shorebird updater instance.
  final ShorebirdUpdater _updater;

  /// Handles application restart functionality.
  final TerminateRestart _terminateRestart;

  /// Clock used for determining throttling intervals.
  final DateTime Function() _now;

  /// Lifecycle listener used to recheck updates when the app resumes.
  AppLifecycleListener? _listener;

  /// Tracks whether initialization (e.g., [TerminateRestart]) has been performed.
  bool _isInitialized = false;

  /// Prevents concurrent update operations.
  bool _isUpdating = false;

  /// Stores the timestamp of the last successful update check.
  DateTime? _lastCheck;

  /// Registers an app lifecycle listener to automatically check for updates.
  ///
  /// This should typically be called in your app’s main widget or
  /// inside a top-level widget’s `initState()` method.
  ///
  /// Example:
  /// ```dart
  /// final patchApp = PatchApp(
  ///   confirmDialog: (context) => patchAppConfirmationDialog(context),
  /// );
  ///
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   patchApp.register(context);
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   patchApp.unregister();
  ///   super.dispose();
  /// }
  /// ```
  void register(BuildContext context) {
    unawaited(checkAndUpdate(context));
    _listener = AppLifecycleListener(
      onResume: () => unawaited(checkAndUpdate(context)),
    );
  }

  /// Unregisters the lifecycle listener created by [register].
  ///
  /// This should be called when the widget is disposed to prevent leaks.
  ///
  /// Example:
  /// ```dart
  /// final patchApp = PatchApp(
  ///   confirmDialog: (context) => patchAppConfirmationDialog(context),
  /// );
  ///
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   patchApp.register(context);
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   patchApp.unregister();
  ///   super.dispose();
  /// }
  /// ```
  void unregister() {
    _listener?.dispose();
    _listener = null;
    _isInitialized = false;
  }

  /// Checks for Shorebird updates and applies them if available.
  ///
  /// - Verifies whether updates are available via [ShorebirdUpdater].
  /// - Skips checks if called too soon after a previous one.
  /// - Prompts the user via [confirmDialog] before restarting.
  ///
  /// Returns a [PatchResult] indicating the result:
  /// - [PatchResult.noUpdate] if no update was found or skipped.
  /// - [PatchResult.upToDate] if already on the latest version.
  /// - [PatchResult.restartRequired] if an update was applied and a restart is needed.
  /// - [PatchResult.cancelled] if the restart prompt was dismissed or skipped.
  /// - [PatchResult.failed] if an error occurred and was caught by [onError].
  ///
  /// Throws the exception if [onError] is not provided.
  Future<PatchResult> checkAndUpdate(BuildContext context) async {
    if (!_updater.isAvailable) {
      _log('[PatchApp] Updater unavailable, initialization skipped.');
      return PatchResult.noUpdate;
    }

    if (!_isInitialized) {
      _terminateRestart.initialize();
      _isInitialized = true;
    }

    final now = _now();
    if (_lastCheck != null && now.difference(_lastCheck!) < minInterval) {
      _log('[PatchApp] Skipping update check (too soon).');
      return PatchResult.noUpdate;
    }

    if (_isUpdating) {
      _log('[PatchApp] Update already in progress, skipping.');
      return PatchResult.noUpdate;
    }

    _isUpdating = true;
    _lastCheck = now;
    try {
      _log('[PatchApp] Checking for updates...');
      final status = await _updater.checkForUpdate();

      var requiresRestart = false;
      switch (status) {
        case UpdateStatus.unavailable:
          _log('[PatchApp] No updates available.');
          return PatchResult.noUpdate;
        case UpdateStatus.upToDate:
          _log('[PatchApp] App is up to date.');
          return PatchResult.upToDate;
        case UpdateStatus.outdated:
          _log('[PatchApp] Update available, downloading...');
          await _updater.update();
          _log('[PatchApp] Update applied. Restart required.');
          requiresRestart = true;
        case UpdateStatus.restartRequired:
          _log('[PatchApp] Restart required.');
          requiresRestart = true;
      }

      if (requiresRestart) {
        if (context.mounted) {
          _log('[PatchApp] Showing confirmation dialog...');
          final result = await confirmDialog(context);
          _log('[PatchApp] Confirmation dialog result: $result');
          if (result) {
            _log('[PatchApp] Restarting app...');
            await _terminateRestart.restartApp(
              options: const TerminateRestartOptions(),
            );
            _log('[PatchApp] The app cannot be restarted, restart required.');
            return PatchResult.restartRequired;
          }
          _log('[PatchApp] Restart cancelled by user.');
          return PatchResult.cancelled;
        }

        _log(
          '[PatchApp] Context not mounted, skipping showing confirmation dialog.',
        );
        return PatchResult.restartRequired;
      }

      return PatchResult.noUpdate;
    } catch (e, stack) {
      _log('[PatchApp] Error during update process: $e');
      if (onError != null) {
        onError!(e, stack);
        return PatchResult.failed;
      }
      rethrow;
    } finally {
      _isUpdating = false;
    }
  }

  /// Prints debug logs if [debug] mode is enabled.
  ///
  /// Used internally to trace update operations.
  void _log(String message) {
    if (debug) {
      debugPrint(message);
    }
  }
}
