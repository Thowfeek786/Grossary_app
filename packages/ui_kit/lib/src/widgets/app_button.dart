import 'package:flutter/material.dart';
import 'package:core/core.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _getForegroundColor(),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: _getForegroundColor()),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _getForegroundColor(),
                    )),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: _buildButton(context, child),
    );
  }

  Widget _buildButton(BuildContext context, Widget child) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: shape,
            elevation: 0,
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
            shape: shape,
            elevation: 0,
          ),
          child: child,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: shape,
          ),
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: shape,
          ),
          child: child,
        );
      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            shape: shape,
            elevation: 0,
          ),
          child: child,
        );
    }
  }

  Color _getForegroundColor() {
    switch (variant) {
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppColors.primary;
      default:
        return AppColors.white;
    }
  }
}
