# Patch App

A lightweight helper to **patch your Flutter app at runtime** using [shorebird\_code\_push](https://pub.dev/packages/shorebird_code_push) and [terminate\_restart](https://pub.dev/packages/terminate_restart).

It handles:

* Checking for updates from Shorebird
* Downloading and applying patches
* Prompting the user with a restart dialog
* Restarting the app safely when accepted

---

## ✨ Features

* 🔍 Check for patches from the Shorebird server
* ⬇️ Download and apply updates on the fly
* 💬 Show a customizable confirmation dialog
* 🔄 Restart the app with one line of code
* ⏱️ Built-in safeguard (`minInterval`) to avoid excessive update checks
* ⚠️ Error handling via callback or enum result

---

## ⚙️ Getting Started

### iOS Setup

Add the following to your **`Info.plist`**:

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

<key>NSUserNotificationAlertStyle</key>
<string>Alert</string>

<key>NSUserNotificationUsageDescription</key>
<string>Notifications are used to restart the app when needed</string>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.ahmedsleem.terminate_restart.restart</string>
</array>
```

### Android Setup

✅ No additional configuration is required.

---

## 🚀 Usage

You can trigger patch checks from a widget, typically in your app root:

```dart
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkAndUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdate();
    }
  }

  Future<void> _checkAndUpdate() async {
    final result = await PatchApp.instance.checkAndUpdate(
      confirmDialog: () => patchAppConfirmationDialog(context),
      minInterval: const Duration(minutes: 15),
      onError: (error, stack) {
        debugPrint("Update failed: $error");
      },
    );

    debugPrint("Patch check result: $result");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
```

---

## 🧩 Handling `BuildContext` Issues

If you encounter `BuildContext`-related errors when showing your own dialog (it safe when using `patchAppConfirmationDialog`):

```dart
PatchApp.instance.checkAndUpdate(
  confirmDialog: () async {
    await WidgetsBinding.instance.endOfFrame; // ensure safe dialog call
    if (!context.mounted) return false;

    return customConfirmationDialog(context);
  },
  onError: (error, stack) {
    debugPrint("Update failed: $error");
  },
);
```

---

## 📊 Return Values

`checkAndUpdate` returns a `PatchResult` enum so you can react programmatically:

```dart
enum PatchResult {
  noUpdate,        // No updater or no update found
  upToDate,        // Already latest version
  restartRequired, // Restart needed to apply patch (users disagree to update)
  failed,          // Error occurred
}
```

---

## ✅ Best Practices

* Combine `minInterval` with `Timer.periodic` for regular background checks.
* Trigger a check on **app resume** using `didChangeAppLifecycleState`.
* Always provide an `onError` callback in production to catch unexpected failures. If `onError` is provided, the method will return `PatchResult.failed` on error. Otherwise, the error will be rethrown.
