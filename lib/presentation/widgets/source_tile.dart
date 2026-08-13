import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/source.dart';

/// Tarjeta que representa una fuente analizada.
class SourceTile extends StatelessWidget {
  final Source source;

  const SourceTile({super.key, required this.source});

  IconData get _icon {
    switch (source.type) {
      case SourceType.github:
        return Icons.code;
      case SourceType.organization:
        return Icons.business_outlined;
      case SourceType.web:
        return Icons.public;
      case SourceType.social:
        return Icons.groups;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyzed = source.status == SourceStatus.analyzed;

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title.isEmpty ? source.url : source.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: AppColors.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source.type.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                analyzed ? Icons.check_circle : Icons.error_outline,
                size: 20,
                color: analyzed ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
          if (source.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              source.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.link, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: SelectableText(
                  source.finalUrl,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryDim,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Consultada: ${source.consultedAt.day.toString().padLeft(2, '0')}/${source.consultedAt.month.toString().padLeft(2, '0')}/${source.consultedAt.year} ${source.consultedAt.hour.toString().padLeft(2, '0')}:${source.consultedAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
