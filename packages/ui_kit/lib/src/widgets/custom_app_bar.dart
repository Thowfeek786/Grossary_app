import 'package:flutter/material.dart';
import 'package:core/core.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkBackground = backgroundColor != null &&
        backgroundColor != AppColors.white &&
        backgroundColor != Colors.white;
    final fgColor = foregroundColor ?? (isDarkBackground ? Colors.white : AppColors.textPrimary);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.white,
      foregroundColor: fgColor,
      iconTheme: IconThemeData(color: fgColor),
      elevation: elevation,
      scrolledUnderElevation: 1,
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      bottom: bottom,
      leading: leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDarkBackground ? Colors.white.withValues(alpha: 0.16) : AppColors.grey100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: fgColor),
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: fgColor,
        ),
      ),
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: fgColor,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
