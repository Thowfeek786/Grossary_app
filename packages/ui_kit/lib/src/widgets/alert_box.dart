import 'package:flutter/material.dart';
import 'package:core/core.dart';

enum AlertType { info, success, warning, error }

class AlertBox extends StatelessWidget {
  final String message;
  final AlertType type;

  const AlertBox({
    super.key,
    required this.message,
    this.type = AlertType.info,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case AlertType.info:
        bgColor = AppColors.primary.withValues(alpha: 0.08);
        iconColor = AppColors.primary;
        icon = Icons.info_outline_rounded;
        break;
      case AlertType.success:
        bgColor = AppColors.success.withValues(alpha: 0.08);
        iconColor = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case AlertType.warning:
        bgColor = AppColors.warning.withValues(alpha: 0.08);
        iconColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.error:
        bgColor = AppColors.error.withValues(alpha: 0.08);
        iconColor = AppColors.error;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: iconColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
