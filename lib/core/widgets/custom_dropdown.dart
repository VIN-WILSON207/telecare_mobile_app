import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget? prefixIcon;
  final bool isExpanded;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.hintText,
    this.backgroundColor = AppTheme.cardWhite,
    this.borderColor = const Color(0xFFE2E8F0),
    this.borderRadius = AppTheme.radiusMedium,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.prefixIcon,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: isExpanded,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items,
          onChanged: onChanged,
          hint: hintText != null
              ? Text(
                  hintText!,
                  style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 14),
                )
              : null,
          style: const TextStyle(color: AppTheme.neutralDark, fontSize: 14),
          dropdownColor: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(borderRadius),
          selectedItemBuilder: items.isNotEmpty
              ? (context) => items.map((item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: DefaultTextStyle(
                        style: const TextStyle(color: AppTheme.neutralDark, fontSize: 14),
                        child: item.child,
                      ),
                    );
                  }).toList()
              : null,
          iconEnabledColor: AppTheme.neutralDark,
        ),
      ),
    );
  }
}
