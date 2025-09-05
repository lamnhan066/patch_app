import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:terminate_restart/terminate_restart.dart';

class PatchApp {
  static PatchApp instance = PatchApp._();

  PatchApp._()
      : _updater = ShorebirdUpdater(),
        _terminateRestart = TerminateRestart.instance;

  final ShorebirdUpdater _updater;
  final TerminateRestart _terminateRestart;

  bool _needToRestart = false;
  bool _isUpdating = false;
  DateTime? _lastCheck;

  Future<void> initialize() async {
    if (!_updater.isAvailable) {
      return;
    }

    _terminateRestart.initialize();
  }

  Future<void> update({
    /// A function that shows a confirmation dialog to the user.
    ///
    /// If the user confirms, the app will restart to apply the update.
    /// If the user cancels, the app will continue running without restarting.
    ///
    /// Use [confirmationRestart()] for a default implementation.
    required Future<bool> Function() confirmDialog,
    final Duration minInterval = const Duration(minutes: 15),
    final bool debug = false,
  }) async {
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < minInterval) {
      return;
    }
    _lastCheck = now;

    if (_isUpdating) return;
    _isUpdating = true;

    void printDebug(String message) {
      if (debug) {
        debugPrint(message);
      }
    }

    printDebug('[Patch App] Checking for updates...');

    if (!_updater.isAvailable) {
      printDebug('[Patch App] Unavailable');
      _isUpdating = false;
      return;
    }

    if (!_needToRestart) {
      final status = await _updater.checkForUpdate();

      switch (status) {
        case UpdateStatus.unavailable:
          printDebug('[Patch App] Unavailable');
          break;
        case UpdateStatus.upToDate:
          printDebug('[Patch App] Up to date');
          break;
        case UpdateStatus.outdated:
          printDebug('[Patch App] Outdated, updating...');
          try {
            await _updater.update();
            _needToRestart = true;
            printDebug('[Patch App] Updated successfully, restart required');
          } on UpdateException catch (e) {
            printDebug('[Patch App] Failed to apply update: $e');
          }
          break;
        case UpdateStatus.restartRequired:
          printDebug('[Patch App] Restart required');
          _needToRestart = true;
          break;
      }
    }

    if (_needToRestart && await confirmDialog()) {
      await _terminateRestart.restartApp(
        options: TerminateRestartOptions(terminate: true),
      );
    }

    _isUpdating = false;
  }
}
