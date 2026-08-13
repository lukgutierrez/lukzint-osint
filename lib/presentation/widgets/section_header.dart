import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Encabezado de sección con divisor decorativo.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              ?(subtitle == null
                  ? null
                  : Text(subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
