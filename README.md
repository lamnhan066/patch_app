# Patch App

Patch the app muanually by combining [shorebird_code_push](https://pub.dev/packages/shorbird_code_push) and [terminate_restart](https://pub.dev/packages/terminate_restart)

## Features

- Check the patch from the shorebird server
- Download it if it's available
- Show an dialog to ask users for restarting
- Restart if users press the accept button

## Getting started

### IOS

Add this to `Info.plist`:

    ```txt
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
    <string>alert</string>
    <key>NSUserNotificationUsageDescription</key>
    <string>Notifications are used to restart the app when needed</string>
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>com.ahmedsleem.terminate_restart.restart</string>
    </array>
    ```

### Android

No specific configuration

## Usage

Initialize:

    ```dart
    void main() {
        WidgetsFlutterBinding.ensureInitialized();
        PatchApp.instance.initialize();
    }
    ```

Check for the update:

    ```dart
    class PageHome extends StatefulWidget {
        const PageHome({super.key});

        @override
        PageHomeState createState() => PageHomeState();
    }

    class PageHomeState extends State<PageHome> with WidgetsBindingObserver {
        @override
        void initState() {
            WidgetsBinding.instance.addObserver(this);
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
                PatchApp.instance.update(
                    confirmDialog: () => patchAppConfirmationDialog(context),
                );
            }
        }

        @override
        Widget build(BuildContext context) {
            return Scaffold();
        }
    }
    ```
