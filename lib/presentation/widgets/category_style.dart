import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/finding.dart';

/// Estilo (color e icono) por categoría de hallazgo.
class CategoryStyle {
  CategoryStyle._();

  static Color colorOf(FindingCategory category) {
    switch (category) {
      case FindingCategory.identity:
        return AppColors.info;
      case FindingCategory.organization:
        return AppColors.warning;
      case FindingCategory.project:
        return AppColors.success;
      case FindingCategory.content:
        return AppColors.violet;
      case FindingCategory.metadata:
      case FindingCategory.other:
        return AppColors.textMuted;
    }
  }

  static IconData iconOf(FindingCategory category) {
    switch (category) {
      case FindingCategory.identity:
        return Icons.person_outline;
      case FindingCategory.organization:
        return Icons.business_outlined;
      case FindingCategory.project:
        return Icons.folder_outlined;
      case FindingCategory.content:
        return Icons.article_outlined;
      case FindingCategory.metadata:
        return Icons.tag;
      case FindingCategory.other:
        return Icons.more_horiz;
    }
  }
}

/// Barra de confianza visual en función del valor numérico.
class ConfidenceBar extends StatelessWidget {
  final double confidence;

  const ConfidenceBar({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 0.9
        ? AppColors.success
        : confidence >= 0.6
            ? AppColors.warning
            : AppColors.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(confidence * 100).round()}%',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
