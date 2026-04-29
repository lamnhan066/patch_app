# Changelog

## 0.2.0

* **BREAKING CHANGE:**
  * feat: change `register` to use named arguments and support deferred startup checks via `navigatorKey`.
  * Call `patchApp.register(context: context)` for the common case, or `patchApp.register(navigatorKey: navigatorKey)` when the navigator context is not ready yet.
* feat: add optional `timeout` to `PatchApp.register(...)` to stop deferred registration retries after a maximum wait duration.
* feat: add `timeout` to `PatchAppScope` and forward it to registration for both `context` and `navigatorKey` flows.
* feat: bump `terminate_restart` to `v1.1.0` and `shorebird_code_push` to `v2.0.6`.
* docs: update the README usage examples to match the new registration flow.

## 0.1.3

* feat: return `PatchResult.cancelled` when the restart prompt is dismissed so callers can distinguish user-aborted restarts from genuine updates.
* fix: only start throttling after an update run begins and report `PatchResult.restartRequired` once the restart is accepted (or when the dialog cannot be shown) so cancelled restarts no longer surface as required.
* docs: clarify the confirmation/result contract in the README.

## 0.1.2

* feat: add useRootNavigator option to patchAppConfirmationDialog.

## 0.1.1

* feat: add Flutter example app integrating patch_app.
* style: reformat dialog builder indentation.

## 0.1.0

* **BREAKING CHANGE:**
  * feat: convert PatchApp to instance-based lifecycle-aware updater.
  * Use dart `^3.7.0` and flutter `>=3.29.0`.
* Update docs and README.

* **MIGRATION GUIDE**:

  Old version:

  ```dart
  await PatchApp.instance.checkAndUpdate(
      confirmDialog: () => patchAppConfirmationDialog(context: context),
      minInterval: const Duration(minutes: 15),
      onError: (error, stack) {
        debugPrint("Update failed: $error");
      },
  );
  ```

  New version:
  
  ```dart
  PatchApp(
    confirmDialog: (context) => patchAppConfirmationDialog(context: context),
    minInterval: const Duration(minutes: 15),
    onError: (error, stack) => debugPrint('Update failed: $error'),
  ).checkAndUpdate(context);
  ```

## 0.0.4

* Rename from `update` to `checkAndUpdate`.
* Add `PatchResult` as the result of `checkAndUpdate`.
* Enhance `patchAppConfirmationDialog` with safety checks for build phase and context mounting.
* Improve the default dialog text.
* Update the README.

## 0.0.3

* Remove the `initialize` method.
* Improve the `update` logic.

## 0.0.2

* Improve the dialog.

## 0.0.1

* Initial release.
