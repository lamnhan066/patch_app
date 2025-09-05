import 'package:flutter/material.dart';

Future<bool> patchAppConfirmationDialog({
  required BuildContext context,
  String title = 'Restart to Update',
  String content = 'A new update is available and has been downloaded.\n\n'
      'Would you like to restart the app to apply the update?',
  String cancelLabel = 'CANCEL',
  String restartLabel = 'RESTART',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 32,
        color: ColorScheme.of(context).primary,
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelLabel,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            restartLabel,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
