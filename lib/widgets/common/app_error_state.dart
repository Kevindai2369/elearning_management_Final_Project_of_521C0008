import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Consistent error state widget
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'Đã xảy ra lỗi',
              style: AppTheme.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
