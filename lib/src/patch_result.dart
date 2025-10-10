/// @docImport '../patch_app.dart';
library;

/// Represents the outcome of a patch update attempt.
///
/// Returned by [PatchApp.checkAndUpdate] to indicate whether a patch was found,
/// applied, or if an error occurred during the process.
///
/// You can use this result to determine the next action in your app logic, such as
/// notifying the user, triggering a restart, or logging an error.
enum PatchResult {
  /// Indicates that no updater is available or no patch update was found.
  noUpdate,

  /// Indicates that the app is already running the latest version.
  upToDate,

  /// Indicates that a patch has been successfully downloaded and staged,
  /// and a restart is required to apply it.
  restartRequired,

  /// Indicates that an error occurred during the patching or update process.
  failed,
}
