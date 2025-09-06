# Patch App

Patch your Flutter app manually by combining [shorebird_code_push](https://pub.dev/packages/shorebird_code_push) and [terminate_restart](https://pub.dev/packages/terminate_restart).

## Features

- Check for patches from the Shorebird server
- Download available patches
- Prompt users with a dialog to restart the app
- Restart the app if the user accepts

## Getting Started

### iOS

Add the following to your `Info.plist`:

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

### Android

No additional configuration required.

## Usage

Check for updates in your widget:

```dart
class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _patchApp();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _patchApp();
    }
  }

  void _patchApp() {
    PatchApp.instance.check(
      confirmDialog: () => patchAppConfirmationDialog(context),
      minInterval: const Duration(minutes: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
```

> **Note:**  
> If you encounter context-related errors, consider wrapping `_patchApp` inside `WidgetsBinding.instance.addPostFrameCallback`. Using the default `patchAppConfirmationDialog` is safe.
