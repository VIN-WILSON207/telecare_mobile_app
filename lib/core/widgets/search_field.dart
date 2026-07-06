import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'telecare_ui.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showClear;
  final Color backgroundColor;
  final Color borderColor;
  final Color? hintColor;
  final Color? textColor;
  final double borderRadius;
  final Widget? prefixIcon;
  final TextInputAction textInputAction;
  final EdgeInsetsGeometry contentPadding;

  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.showClear = false,
    this.backgroundColor = AppTheme.cardWhite,
    this.borderColor = const Color(0xFFE2E8F0),
    this.hintColor,
    this.textColor,
    this.borderRadius = AppTheme.radiusMedium,
    this.prefixIcon,
    this.textInputAction = TextInputAction.search,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: textInputAction,
      cursorColor: TeleCareInputStyles.cursorColor,
      style: TextStyle(
        color: textColor ?? Colors.black,
        fontSize: 15,
      ),
      decoration: TeleCareInputStyles.decoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: showClear && onClear != null
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                color: AppTheme.neutralMedium,
                onPressed: onClear,
              )
            : null,
        dense: true,
        fillColor: backgroundColor,
      ).copyWith(
        hintStyle: TextStyle(
          color: hintColor ?? AppTheme.neutralMedium,
          fontSize: 15,
        ),
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}
