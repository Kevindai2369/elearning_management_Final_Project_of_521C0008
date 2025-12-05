import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Polished drawer header with gradient background
class AppDrawerHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String? avatarUrl;
  final Gradient gradient;

  const AppDrawerHeader({
    super.key,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingM,
            AppTheme.spacingL,
            AppTheme.spacingL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with border and shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  key: ValueKey('drawer-avatar-$avatarUrl'),
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: hasAvatar
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            cacheWidth: 160,
                            cacheHeight: 160,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildInitials(fullName);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _buildInitials(fullName),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Name
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              // Email
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Text(
      initials,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
      ),
    );
  }
}
