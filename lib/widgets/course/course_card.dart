import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../utils/app_theme.dart';

/// Polished course card widget with consistent styling
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showStudentCount;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.trailing,
    this.showStudentCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        side: BorderSide(
          color: AppTheme.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border(
              left: BorderSide(
                color: course.getColor(),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course color indicator
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: course.getColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Icon(
                        Icons.school,
                        color: course.getColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    // Course info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: AppTheme.heading3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: AppTheme.spacingXS),
                              Expanded(
                                child: Text(
                                  course.instructorName,
                                  style: AppTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (course.description.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    course.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showStudentCount)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: AppTheme.spacingXS),
                            Text(
                              '${course.studentIds.length} học sinh',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (trailing != null) trailing!,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
