enum PatchResult {
  /// Updater not available or no update found
  noUpdate,

  /// Already on latest version
  upToDate,

  /// Update already staged and restart is needed
  restartRequired,

  /// Any error during the process
  failed,
}
