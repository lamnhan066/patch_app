# Patch App

A lightweight helper to **patch your Flutter app at runtime** using [shorebird_code_push](https://pub.dev/packages/shorebird_code_push) and [terminate_restart](https://pub.dev/packages/terminate_restart).

It automatically checks for Shorebird updates, applies patches, and restarts your app safely when accepted.

---

## Features

* Check and apply Shorebird patches dynamically
* Show a customizable restart confirmation dialog
* Restart the app safely with one line of code
* Register with `context:`, `navigatorKey:`, or `binding:` so startup checks can wait for the navigator to be ready
* Optional `timeout` to stop deferred navigator/context retries after a max wait duration
* Built-in `minInterval` to limit check frequency and prevent redundant checks
* Optional error handling via callback, with `PatchResult.failed` for caught errors
* Only report `PatchResult.restartRequired` when the restart dialog is accepted (or cannot be shown), while rejected prompts return `PatchResult.cancelled`

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
  Widget build(BuildContext context) {
    return PatchAppScope(
      patchApp: patchApp,
      child: FilledButton(
        onPressed: () => patchApp.checkAndUpdate(context), // Check and update manually
        child: const Text('Check and Update'),
      ),
    );
  }
}
```

---

### `PatchAppScope`

* Wrap any subtree in `PatchAppScope` to register automatically for the wrapped widget.
  It calls `register()` in `initState()` and `unregister()` in `dispose()` for you.
* If you are wrapping an app root that needs to wait for a navigator, pass a `navigatorKey` to the scope.
* If you need to control deferred registration scheduling in tests or custom bindings, pass a `binding` to the scope.
* If you want deferred registration to stop after a maximum wait, pass `timeout`:

```dart
PatchAppScope(
  patchApp: patchApp,
  navigatorKey: navigatorKey,
  timeout: const Duration(seconds: 5),
  child: const MyApp(),
)
```

### `register(context:)` and `unregister()`

* **`register(context)`**
  Automatically checks for updates when the app starts or resumes.
  Should be called once in `initState()`.
  If you need to wait for the navigator to become available, pass a
  `navigatorKey` instead:
  `patchApp.register(navigatorKey: navigatorKey)`.
  To stop retrying deferred registration after a max duration, pass
  `timeout`:
  `patchApp.register(navigatorKey: navigatorKey, timeout: const Duration(seconds: 5))`.
  The `context:` and `navigatorKey:` arguments are named.

* **`unregister()`**
  Cleans up the lifecycle listener created by `register()`.
  Always call this in `dispose()`.

---

## Patch Results

```dart
enum PatchResult {
  noUpdate,        // No updater or no patch available
  upToDate,        // Already on the latest version
  cancelled,       // Restart prompt dismissed or skipped
  restartRequired, // Patch applied; restart needed
  failed,          // Error during the update
}
```

`cancelled` is returned when the confirmation dialog is dismissed, while `restartRequired` is only emitted after the user accepts a restart (or if the dialog cannot be shown because the context was unmounted), signaling that a restart is still needed.

---

## Tips

* Always provide an `onError` callback in production to capture unexpected failures.
* If `onError` is provided, it runs before `PatchResult.failed` is returned.
* If omitted, the error is still converted into `PatchResult.failed`.
