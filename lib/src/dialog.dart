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
      backgroundColor: const Color(0xFF2A2A2A),
      icon: const Icon(
        Icons.warning_amber_rounded,
        size: 32,
        color: Colors.greenAccent,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          color: Colors.grey[400],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(
            Icons.cancel_rounded,
            size: 16,
            color: Colors.grey,
          ),
          label: Text(
            cancelLabel,
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(
            Icons.refresh_rounded,
            size: 16,
          ),
          label: Text(
            restartLabel,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
