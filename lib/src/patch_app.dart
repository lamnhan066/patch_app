import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:terminate_restart/terminate_restart.dart';

/// A helper class that manages code push updates and restarts.
///
/// Typical usage:
/// ```dart
/// await PatchApp.instance.update(
///   confirmDialog: () => patchAppConfirmationDialog(context: context),
/// );
/// ```
class PatchApp {
  /// Singleton instance of [PatchApp].
  static final PatchApp instance = PatchApp._();

  PatchApp._()
      : _updater = ShorebirdUpdater(),
        _terminateRestart = TerminateRestart.instance;

  final ShorebirdUpdater _updater;
  final TerminateRestart _terminateRestart;

  bool _isInitialized = false;
  bool _isUpdating = false;
  DateTime? _lastCheck;
  bool _debug = false;

  /// Checks for updates and applies them if available.
  ///
  /// - [confirmDialog] is a function that shows a confirmation dialog.
  ///   It should return `true` if the app may restart, `false` otherwise.
  /// - [minInterval] specifies how often updates can be checked.
  /// - [onUpdateFailed] is an optional callback invoked if an update fails.
  /// - [debug] enables debug logging if set to `true`.
  Future<void> update({
    required Future<bool> Function() confirmDialog,
    Duration minInterval = const Duration(minutes: 15),
    void Function(Object error)? onUpdateFailed,
    bool debug = false,
  }) async {
    _debug = debug;
    if (!_updater.isAvailable) {
      _log('[PatchApp] Updater unavailable, initialization skipped.');
      return;
    }

    if (!_isInitialized) {
      _terminateRestart.initialize();
      _isInitialized = true;
    }

    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < minInterval) {
      _log('[PatchApp] Skipping update check (too soon).');
      return;
    }
    _lastCheck = now;

    if (_isUpdating) {
      _log('[PatchApp] Update already in progress, skipping.');
      return;
    }

    _isUpdating = true;
    try {
      _log('[PatchApp] Checking for updates...');

      final status = await _updater.checkForUpdate();

      switch (status) {
        case UpdateStatus.unavailable:
          _log('[PatchApp] No updates available.');
          return;
        case UpdateStatus.upToDate:
          _log('[PatchApp] App is up to date.');
          return;
        case UpdateStatus.outdated:
          _log('[PatchApp] Update available, downloading...');
          try {
            await _updater.update();
            _log('[PatchApp] Update applied. Restart required.');
          } on UpdateException catch (e) {
            _log('[PatchApp] Update failed: $e');
            onUpdateFailed?.call(e);
            return;
          } catch (e) {
            _log('[PatchApp] Unexpected error during update: $e');
            onUpdateFailed?.call(e);
            return;
          }
          break;
        case UpdateStatus.restartRequired:
          _log('[PatchApp] Restart required.');
          break;
      }

      if (await confirmDialog()) {
        _log('[PatchApp] Restarting app...');
        await _terminateRestart.restartApp(
          options: TerminateRestartOptions(terminate: true),
        );
      }
    } catch (e) {
      _log('[PatchApp] Error during update process: $e');
      onUpdateFailed?.call(e);
    } finally {
      _isUpdating = false;
    }
  }

  void _log(String message) {
    if (_debug) {
      debugPrint(message);
    }
  }
}
