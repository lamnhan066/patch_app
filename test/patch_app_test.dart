import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patch_app/patch_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:terminate_restart/terminate_restart.dart';

class _FakeClock {
  _FakeClock(this._current);

  DateTime _current;

  DateTime now() => _current;

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}

class _FakeShorebirdUpdater implements ShorebirdUpdater {
  _FakeShorebirdUpdater({
    bool isAvailable = true,
    Future<UpdateStatus> Function({UpdateTrack? track})? onCheckForUpdate,
    Future<void> Function({UpdateTrack? track})? onUpdate,
  }) : _isAvailable = isAvailable,
       _onCheckForUpdate =
           onCheckForUpdate ??
           (({UpdateTrack? track}) async => UpdateStatus.unavailable),
       _onUpdate = onUpdate ?? (({UpdateTrack? track}) async {});

  final Future<UpdateStatus> Function({UpdateTrack? track}) _onCheckForUpdate;
  final Future<void> Function({UpdateTrack? track}) _onUpdate;

  int checkForUpdateCalls = 0;
  int updateCalls = 0;
  bool _isAvailable;

  @override
  bool get isAvailable => _isAvailable;

  set isAvailable(bool value) => _isAvailable = value;

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async {
    checkForUpdateCalls++;
    return _onCheckForUpdate(track: track);
  }

  @override
  Future<Patch?> readCurrentPatch() async => null;

  @override
  Future<Patch?> readNextPatch() async => null;

  @override
  Future<void> update({UpdateTrack? track}) async {
    updateCalls++;
    await _onUpdate(track: track);
  }
}

class _FakeTerminateRestart implements TerminateRestart {
  bool initialized = false;
  int restartCalls = 0;

  @override
  void initialize({VoidCallback? onRootReset}) {
    initialized = true;
    onRootReset?.call();
  }

  @override
  Future<bool> restartApp({required TerminateRestartOptions options}) async {
    restartCalls++;
    return true;
  }

  @override
  Future<bool> restartAppWithConfirmation(
    BuildContext context, {
    String title = 'Restart Required',
    String message = 'The app needs to restart to apply changes.',
    String confirmText = 'Restart Now',
    String cancelText = 'Later',
    bool clearData = false,
    bool preserveKeychain = false,
    bool preserveUserDefaults = false,
    bool terminate = true,
  }) async {
    return false;
  }
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        capturedContext = context;
        return const SizedBox.shrink();
      },
    ),
  );
  return capturedContext;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('throttles update checks based on minInterval', (tester) async {
    final clock = _FakeClock(DateTime(2024, 1, 1, 12));
    final updater = _FakeShorebirdUpdater(
      onCheckForUpdate: ({UpdateTrack? track}) async => UpdateStatus.upToDate,
    );
    final restart = _FakeTerminateRestart();

    final patchApp = PatchApp(
      confirmDialog: (_) async => true,
      updater: updater,
      terminateRestart: restart,
      now: clock.now,
    );

    final context = await _pumpContext(tester);

    final firstResult = await patchApp.checkAndUpdate(context);
    expect(firstResult, PatchResult.upToDate);
    expect(updater.checkForUpdateCalls, 1);

    clock.advance(const Duration(minutes: 1));
    final throttledResult = await patchApp.checkAndUpdate(context);
    expect(throttledResult, PatchResult.noUpdate);
    expect(updater.checkForUpdateCalls, 1);
  });

  testWidgets('prevents concurrent update checks', (tester) async {
    final clock = _FakeClock(DateTime(2024, 1, 1, 12));
    final completer = Completer<UpdateStatus>();
    final updater = _FakeShorebirdUpdater(
      onCheckForUpdate: ({UpdateTrack? track}) => completer.future,
    );
    final restart = _FakeTerminateRestart();

    final patchApp = PatchApp(
      confirmDialog: (_) async => true,
      updater: updater,
      terminateRestart: restart,
      now: clock.now,
    );

    final context = await _pumpContext(tester);

    final firstCall = patchApp.checkAndUpdate(context);
    final concurrentResult = await patchApp.checkAndUpdate(context);

    expect(concurrentResult, PatchResult.noUpdate);
    expect(updater.checkForUpdateCalls, 1);

    completer.complete(UpdateStatus.upToDate);
    final firstResult = await firstCall;
    expect(firstResult, PatchResult.upToDate);
  });

  testWidgets('returns cancelled when user dismisses restart dialog', (
    tester,
  ) async {
    final clock = _FakeClock(DateTime(2024, 1, 1, 12));
    final updater = _FakeShorebirdUpdater(
      onCheckForUpdate:
          ({UpdateTrack? track}) async => UpdateStatus.restartRequired,
    );
    final restart = _FakeTerminateRestart();

    final patchApp = PatchApp(
      confirmDialog: (_) async => false,
      updater: updater,
      terminateRestart: restart,
      now: clock.now,
    );

    final context = await _pumpContext(tester);

    final result = await patchApp.checkAndUpdate(context);

    expect(result, PatchResult.cancelled);
    expect(restart.restartCalls, 0);
  });

  testWidgets('returns restartRequired when user accepts restart', (
    tester,
  ) async {
    final clock = _FakeClock(DateTime(2024, 1, 1, 12));
    final updater = _FakeShorebirdUpdater(
      onCheckForUpdate: ({UpdateTrack? track}) async => UpdateStatus.outdated,
      onUpdate: ({UpdateTrack? track}) async {},
    );
    final restart = _FakeTerminateRestart();

    final patchApp = PatchApp(
      confirmDialog: (_) async => true,
      updater: updater,
      terminateRestart: restart,
      now: clock.now,
    );

    final context = await _pumpContext(tester);

    final result = await patchApp.checkAndUpdate(context);

    expect(result, PatchResult.restartRequired);
    expect(updater.updateCalls, 1);
    expect(restart.restartCalls, 1);
  });

  testWidgets('returns noUpdate when updater is unavailable', (tester) async {
    final clock = _FakeClock(DateTime(2024, 1, 1, 12));
    final updater = _FakeShorebirdUpdater(isAvailable: false);
    final restart = _FakeTerminateRestart();

    final patchApp = PatchApp(
      confirmDialog: (_) async => true,
      updater: updater,
      terminateRestart: restart,
      now: clock.now,
    );

    final context = await _pumpContext(tester);

    final result = await patchApp.checkAndUpdate(context);

    expect(result, PatchResult.noUpdate);
    expect(restart.initialized, isFalse);
  });
}
