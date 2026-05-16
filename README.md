# Patch App

A lightweight helper to **patch your Flutter app at runtime** using [shorebird_code_push](https://pub.dev/packages/shorebird_code_push).

It automatically checks for Shorebird updates, applies patches, and restarts your app safely when accepted. Restart behavior is provided by an internal `Restart` abstraction — by default the package uses `terminate_restart` on mobile and web, and `restart_app` on other desktop platforms, but you can inject a custom `restart` implementation (useful for tests).

---

## Features

* Check and apply Shorebird patches dynamically
* Show a customizable restart confirmation dialog
* Restart the app safely with one line of code
* Inject a custom `restart` implementation (handy for testing)
* Register with `context:`, `navigatorKey:`, or `binding:` so startup checks can wait for the navigator to be ready
* Optional `timeout` to stop deferred navigator/context retries after a max wait duration
* Built-in `minInterval` to limit check frequency and prevent redundant checks
* Optional error handling via callback, with `PatchResult.failed` for caught errors
* Return `PatchResult.success` when a patch is applied and the restart completed successfully (if a restart was performed)
* Only report `PatchResult.restartRequired` when the restart dialog is accepted (or cannot be shown), while rejected prompts return `PatchResult.cancelled`
* Optional `onResult` callback invoked after each `checkAndUpdate` with the active `BuildContext` and the resulting `PatchResult` (useful to show follow-up UI like a manual-restart dialog).

---

## Setup

### iOS

Add the following to your **`Info.plist`** to enable restarts on iOS (used by the package's default restart implementation which relies on [terminate_restart](https://pub.dev/packages/terminate_restart)):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        </array>
    </dict>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        </array>
        <key>CFBundleURLName</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    </dict>
</array>
```

### Android, Windows, MacOS, Linux and Web

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

### Testing / Custom restart implementations

The package exposes an internal `Restart` abstraction (with `Future<void> initialize()` and `Future<bool> restart()`), and the `PatchApp` constructor accepts an optional `restart:` argument. In normal apps you don't need to pass anything — the default implementation handles platform specifics. In tests you can pass a fake implementation to avoid performing real restarts:

```dart
final patchApp = PatchApp(
  confirmDialog: (_) async => true,
  // Optional: inject a test-friendly restart implementation
  restart: MyFakeRestart(),
);
```

Your fake should implement two async methods: `initialize()` and `restart()`.
The `restart()` method should return `true` when the restart succeeded, or `false` when it did not.

### `onResult` callback

`PatchApp` accepts an optional `onResult` callback with the signature `Future<void> Function(BuildContext context, PatchResult result)? onResult`. This is useful to present follow-up UI (for example, when the updater reports that a manual restart is required):

```dart
final patchApp = PatchApp(
  confirmDialog: (context) => patchAppConfirmationDialog(context),
  onResult: (context, result) async {
    // The `context.mounted` should be checked before use
    if (context.mounted && result == PatchResult.restartRequired) {
      await patchAppConfirmationDialog(
        context: context,
        title: 'Manual Restart Required',
        content: 'The app cannot restart automatically to apply the update.\n\n'
            'Please restart the app manually to apply the latest updates.',
        restartLabel: 'OK',
        cancelLabel: 'CANCEL',
      );
    }
  },
);
```

The callback runs only when `context.mounted` is true; otherwise it is
skipped to avoid showing dialogs on unmounted contexts.

---

## Patch Results

```dart
enum PatchResult {
  noUpdate,        // No updater or no patch available
  throttled,       // Check skipped because `minInterval` not reached
  upToDate,        // Already on the latest version
  cancelled,       // Restart prompt dismissed or skipped
  restartRequired, // Patch applied; restart needed
  failed,          // Error during the update
  success,         // Patch applied and restart completed successfully (may not be returned if the process exits before the restart API returns)
}
```

`throttled` is returned when a call to `checkAndUpdate` is skipped because the
configured `minInterval` between checks has not yet elapsed. `cancelled` is
returned when the confirmation dialog is dismissed. `success` is returned when
an update was applied and the app was successfully restarted — note this may
not be returned if the process exits before the restart API can return. `restartRequired` is emitted when a restart is needed but could not be completed automatically (for example when the restart API returns `false`, or when the dialog cannot be shown because the context was unmounted), signaling that a manual restart is still needed.
