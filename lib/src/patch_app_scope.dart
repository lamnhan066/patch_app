import 'package:flutter/widgets.dart';
import 'package:patch_app/patch_app.dart' show PatchApp;
import 'package:patch_app/src/patch_app.dart' show PatchApp;

/// A widget that registers [PatchApp] for the wrapped subtree.
class PatchAppScope extends StatefulWidget {
  /// Creates a scope that automatically registers [patchApp].
  const PatchAppScope({
    required this.patchApp,
    required this.child,
    super.key,
    this.navigatorKey,
    this.binding,
    this.timeout,
  });

  /// The patch manager to register and unregister.
  final PatchApp patchApp;

  /// The widget subtree to wrap.
  final Widget child;

  /// Optional navigator key for apps that need to wait for the navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Optional binding used to schedule deferred registration retries.
  final WidgetsBinding? binding;

  /// Optional timeout to stop deferred registration retries.
  final Duration? timeout;

  @override
  State<PatchAppScope> createState() => _PatchAppScopeState();
}

class _PatchAppScopeState extends State<PatchAppScope> {
  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant PatchAppScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patchApp != widget.patchApp ||
        oldWidget.navigatorKey != widget.navigatorKey ||
        oldWidget.binding != widget.binding) {
      oldWidget.patchApp.unregister();
      _register();
    }
  }

  @override
  void dispose() {
    widget.patchApp.unregister();
    super.dispose();
  }

  void _register() {
    final navigatorKey = widget.navigatorKey;
    if (navigatorKey != null) {
      widget.patchApp.register(
        navigatorKey: navigatorKey,
        binding: widget.binding,
        timeout: widget.timeout,
      );
      return;
    }

    widget.patchApp.register(
      context: context,
      binding: widget.binding,
      timeout: widget.timeout,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
