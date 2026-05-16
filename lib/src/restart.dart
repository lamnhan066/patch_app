import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:restart_app/restart_app.dart' as restart_app;
import 'package:terminate_restart/terminate_restart.dart';

/// A class that defines the interface for restarting the application.
abstract class Restart {
  /// Initializes the restart mechanism, if necessary.
  ///
  /// This method can be used to perform any setup required before
  /// the application can be restarted.
  Future<void> initialize();

  /// Restarts the application.
  Future<bool> restart();
}

/// A default implementation of the [Restart] interface that uses
/// platform-specific methods to restart the app.
///
/// On Web, Android, and iOS, it uses the `terminate_restart` package to
/// restart the app by terminating the process. On other platforms, it uses
/// the `restart_app` package to restart the app.
class DefaultRestart implements Restart {
  /// A default implementation of the [Restart] interface that uses
  /// platform-specific methods to restart the app.
  ///
  /// On Web, Android, and iOS, it uses the `terminate_restart` package to
  /// restart the app by terminating the process. On other platforms, it uses
  /// the `restart_app` package to restart the app.
  const DefaultRestart();

  @override
  Future<void> initialize() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      TerminateRestart.instance.initialize();
    }
  }

  @override
  Future<bool> restart() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return TerminateRestart.instance.restartApp(
        options: const TerminateRestartOptions(),
      );
    } else {
      final result = await restart_app.Restart.restartApp(forceKill: true);
      return result.success;
    }
  }
}
