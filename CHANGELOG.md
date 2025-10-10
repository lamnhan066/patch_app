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
