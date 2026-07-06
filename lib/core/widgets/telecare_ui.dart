import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TeleCareInputStyles {
  const TeleCareInputStyles._();

  static const TextStyle textStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    height: 1.35,
  );

  static const TextStyle formTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 18,
    height: 1.35,
  );

  static const TextStyle hintStyle = TextStyle(
    color: AppTheme.neutralMedium,
    fontSize: 15,
  );

  static const TextStyle labelStyle = TextStyle(
    color: AppTheme.neutralMedium,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle errorStyle = TextStyle(
    color: AppTheme.errorColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const Color cursorColor = AppTheme.primaryColor;

  static InputDecoration decoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
    bool dense = false,
    bool alignLabelWithHint = false,
    Color fillColor = AppTheme.cardWhite,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: fillColor,
      isDense: dense,
      hintStyle: hintStyle,
      labelStyle: labelStyle,
      floatingLabelStyle: labelStyle.copyWith(color: AppTheme.primaryColor),
      errorStyle: errorStyle,
      prefixIconColor: AppTheme.neutralMedium,
      suffixIconColor: AppTheme.neutralMedium,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: dense ? 12 : 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
      ),
    );
  }
}

class TeleCareCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;
  final VoidCallback? onTap;

  const TeleCareCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.28) ??
              const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
