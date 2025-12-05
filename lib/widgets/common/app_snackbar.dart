import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Consistent snackbar helper
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final color = _getColor(type);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: SnackbarType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, type: SnackbarType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: SnackbarType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: SnackbarType.info);
  }

  static Color _getColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return AppTheme.successGreen;
      case SnackbarType.error:
        return AppTheme.errorRed;
      case SnackbarType.warning:
        return AppTheme.warningOrange;
      case SnackbarType.info:
        return AppTheme.infoBlue;
    }
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_outline;
      case SnackbarType.error:
        return Icons.error_outline;
      case SnackbarType.warning:
        return Icons.warning_amber_outlined;
      case SnackbarType.info:
        return Icons.info_outline;
    }
  }
}

enum SnackbarType {
  success,
  error,
  warning,
  info,
}
