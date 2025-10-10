# Patch App

A lightweight helper to **patch your Flutter app at runtime** using [shorebird_code_push](https://pub.dev/packages/shorebird_code_push) and [terminate_restart](https://pub.dev/packages/terminate_restart).

It automatically checks for Shorebird updates, applies patches, and restarts your app safely when accepted.

---

## Features

* Check and apply Shorebird patches dynamically
* Show a customizable restart confirmation dialog
* Restart the app safely with one line of code
* Built-in `minInterval` to limit check frequency
* Optional error handling via callback or `PatchResult`

---

## Setup

### iOS

Add the following to your **`Info.plist`** to enable restarts with [terminate_restart](https://pub.dev/packages/terminate_restart):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    </array>
  </dict>
</array>
```

### Android

No configuration required.

---

## Usage

```dart
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final patchApp = PatchApp(
    confirmDialog: (context) => patchAppConfirmationDialog(context),
    onError: (error, stack) => debugPrint('Update failed: $error'),
  );

  @override
  void initState() {
    super.initState();
    patchApp.register(context); // Auto-checks on start & resume
  }

  @override
  void dispose() {
    patchApp.unregister(); // Stops lifecycle listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => patchApp.checkAndUpdate(context), // Check and update manually
      child: const Text('Check and Update'),
    );
  }
}
```

---

### `register()` and `unregister()`

* **`register(context)`**
  Automatically checks for updates when the app starts or resumes.
  Should be called once in `initState()`.

* **`unregister()`**
  Cleans up the lifecycle listener created by `register()`.
  Always call this in `dispose()`.

---

## Patch Results

```dart
enum PatchResult {
  noUpdate,        // No updater or no patch available
  upToDate,        // Already on the latest version
  restartRequired, // Patch applied; restart needed
  failed,          // Error during the update
}
```

---

## Tips

* Always provide an `onError` callback in production to capture unexpected failures.

  * If `onError` is provided, the method returns `PatchResult.failed` on error.
  * If omitted, the error is rethrown.
