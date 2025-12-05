import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Consistent loading indicators across the app
class AppLoading {
  AppLoading._();

  /// Full screen loading overlay
  static Widget fullScreen({String? message}) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              Text(
                message,
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Inline loading indicator
  static Widget inline({String? message, Color? color}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppTheme.primaryBlue,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text(
              message,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Small loading indicator for buttons
  static Widget button({Color color = Colors.white}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  /// Shimmer loading effect for lists
  static Widget shimmerList({int itemCount = 5}) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return _ShimmerCard();
      },
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: double.infinity, height: 20),
              const SizedBox(height: AppTheme.spacingS),
              _buildShimmerBox(width: 150, height: 14),
              const SizedBox(height: AppTheme.spacingS),
              _buildShimmerBox(width: double.infinity, height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: [
            _controller.value - 0.3,
            _controller.value,
            _controller.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
    );
  }
}
