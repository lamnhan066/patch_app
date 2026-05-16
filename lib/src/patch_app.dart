import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:patch_app/src/patch_result.dart';
import 'package:patch_app/src/restart.dart';
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
  /// - [onError] is called when the update process throws.
  ///   Errors are still reported as [PatchResult.failed].
  /// - [debug] enables debug logging if set to `true`.
  PatchApp({
    required this.confirmDialog,
    this.minInterval = const Duration(minutes: 15),
    this.onError,
    this.debug = false,
    ShorebirdUpdater? updater,
    Restart? restart,
    DateTime Function()? now,
  }) : _updater = updater ?? ShorebirdUpdater(),
       _restart = restart ?? const DefaultRestart(),
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
  final Restart _restart;

  /// Clock used for determining throttling intervals.
  final DateTime Function() _now;

  /// Lifecycle listener used to recheck updates when the app resumes.
  AppLifecycleListener? _listener;

  /// Context supplied to [register], if any.
  BuildContext? _registeredContext;

  /// Navigator key supplied to [register], if any.
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Binding used to retry registration until a context becomes available.
  WidgetsBinding? _binding;

  /// Maximum duration to keep retrying deferred registration.
  Duration? _registrationTimeout;

  /// Deadline after which deferred registration retries stop.
  DateTime? _registrationDeadline;

  /// Prevents scheduling duplicate post-frame retries.
  bool _registrationRetryScheduled = false;

  /// Tracks whether the registration flow is active.
  bool _isActive = true;

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
  /// A navigator key can be supplied when the [BuildContext] is not yet
  /// available. In that case, registration waits until the navigator's
  /// context is mounted. Use [timeout] to stop retrying after a maximum
  /// waiting duration.
  void register({
    BuildContext? context,
    GlobalKey<NavigatorState>? navigatorKey,
    WidgetsBinding? binding,
    Duration? timeout,
  }) {
    if (_listener != null) return;

    if (context == null && navigatorKey == null) {
      throw ArgumentError(
        'Either context or navigatorKey must be provided to register().',
      );
    }

    _registeredContext = context;
    _navigatorKey = navigatorKey;
    _binding = binding ?? WidgetsBinding.instance;
    _registrationTimeout = timeout;
    _registrationDeadline = timeout == null ? null : _now().add(timeout);
    _isActive = true;
    _listener = AppLifecycleListener(onResume: _checkWhenReady);

    _checkWhenReady();
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
    _isActive = false;
    _listener?.dispose();
    _listener = null;
    _registeredContext = null;
    _navigatorKey = null;
    _binding = null;
    _registrationTimeout = null;
    _registrationDeadline = null;
    _registrationRetryScheduled = false;
    _isInitialized = false;
  }

  void _checkWhenReady() {
    if (!_isActive) return;

    final context = _resolveContext();
    if (context != null) {
      _registrationRetryScheduled = false;
      unawaited(checkAndUpdate(context));
      return;
    }

    if (_hasTimedOut()) {
      _registrationRetryScheduled = false;
      return;
    }

    if (_registrationRetryScheduled) return;
    _registrationRetryScheduled = true;
    _binding?.addPostFrameCallback((_) {
      _registrationRetryScheduled = false;
      _checkWhenReady();
    });
  }

  bool _hasTimedOut() {
    final timeout = _registrationTimeout;
    if (timeout == null) return false;

    final deadline = _registrationDeadline;
    if (deadline == null) return false;

    return !_now().isBefore(deadline);
  }

  BuildContext? _resolveContext() {
    final context = _registeredContext;
    if (context != null && context.mounted) {
      return context;
    }

    final navigatorContext = _navigatorKey?.currentState?.context;
    if (navigatorContext != null && navigatorContext.mounted) {
      return navigatorContext;
    }

    return null;
  }

  /// Checks for Shorebird updates and applies them if available.
  ///
  /// - Verifies whether updates are available via [ShorebirdUpdater].
  /// - Skips checks if called too soon after a previous one.
  /// - Prompts the user via [confirmDialog] before restarting.
  ///
  /// Returns a [PatchResult] indicating the result:
  /// - [PatchResult.noUpdate] if no update was found.
  /// - [PatchResult.throttled] if the check was skipped because the minimum
  ///   interval between checks has not been reached.
  /// - [PatchResult.upToDate] if already on the latest version.
  /// - [PatchResult.restartRequired] if an update was applied and a restart is needed.
  /// - [PatchResult.cancelled] if the restart prompt was dismissed or skipped.
  /// - [PatchResult.failed] if an error occurs while checking or applying an update.
  ///
  /// If [onError] is provided, it runs before [PatchResult.failed] is returned.
  Future<PatchResult> checkAndUpdate(BuildContext context) async {
    if (!_updater.isAvailable) {
      _log('[PatchApp] Updater unavailable, initialization skipped.');
      return PatchResult.noUpdate;
    }

    if (!_isInitialized) {
      await _restart.initialize();
      _isInitialized = true;
    }

    if (_isUpdating) {
      _log('[PatchApp] Update already in progress, skipping.');
      return PatchResult.noUpdate;
    }

    final now = _now();
    if (_lastCheck != null && now.difference(_lastCheck!) < minInterval) {
      _log('[PatchApp] Skipping update check (too soon).');
      return PatchResult.throttled;
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
            final result = await _restart.restart();
            if (result) {
              _log('[PatchApp] App restarted successfully.');
              return PatchResult.success;
            } else {
              _log(
                '[PatchApp] The app cannot be restarted, manual restart required.',
              );
              return PatchResult.restartRequired;
            }
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
      // Catch both error and exception
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stack) {
      _log('[PatchApp] Error during update process: $e');
      onError?.call(e, stack);
      return PatchResult.failed;
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
