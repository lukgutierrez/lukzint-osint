import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/finding.dart';
import 'category_style.dart';

/// Tarjeta que representa un hallazgo OSINT.
class FindingTile extends StatelessWidget {
  final Finding finding;

  const FindingTile({super.key, required this.finding});

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.colorOf(finding.category);
    final evidence = finding.evidence;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CategoryStyle.iconOf(finding.category),
                  size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  finding.description,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.text),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  finding.category.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            finding.content,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.5,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ConfidenceBar(confidence: finding.confidence),
              const Spacer(),
              Text(
                '${finding.timestamp.day.toString().padLeft(2, '0')}/${finding.timestamp.month.toString().padLeft(2, '0')}/${finding.timestamp.year}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (evidence != null && evidence.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Evidencia: $evidence',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
