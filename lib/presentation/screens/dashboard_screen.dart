import 'package:flutter/material.dart';

import '../../core/constants/branding.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/investigation.dart';
import '../controllers/investigation_controller.dart';
import '../screens/analyzer_screen.dart';
import '../screens/investigation_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

/// Pantalla principal: listado de investigaciones.
class DashboardScreen extends StatefulWidget {
  final InvestigationController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final objectiveController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva investigación'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej. Análisis de perfil público',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: objectiveController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Objetivo',
                  hintText: '¿Qué se busca confirmar o descartar?',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(dialogContext);
              await widget.controller.create(
                title: title,
                objective: objectiveController.text.trim(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Investigation investigation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar investigación'),
        content: Text(
          '¿Seguro que deseas eliminar "${investigation.title}"? '
          'Se eliminarán sus ${investigation.sources.length} fuentes y '
          '${investigation.findings.length} hallazgos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.delete(investigation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth =
                    constraints.maxWidth > 1200 ? 1200.0 : constraints.maxWidth;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          _buildStats(context),
                          const SizedBox(height: 24),
                          Expanded(child: _buildList(context)),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              AppBranding.watermark,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              AppBranding.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          AppBranding.tagline,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(controller: widget.controller),
              ),
            );
          },
          tooltip: 'Ajustes',
          icon: const Icon(Icons.settings_outlined),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    AnalyzerScreen(controller: widget.controller),
              ),
            );
          },
          icon: const Icon(Icons.travel_explore),
          label: const Text('Analizador'),
        ),
        FilledButton.icon(
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Nueva investigación'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 14),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildStats(BuildContext context) {
    final investigations = widget.controller.investigations;
    final totalSources = investigations.fold<int>(
        0, (sum, inv) => sum + inv.sources.length);
    final totalFindings = investigations.fold<int>(
        0, (sum, inv) => sum + inv.findings.length);

    return Row(
      children: [
        _StatCard(
          icon: Icons.folder_outlined,
          label: 'Investigaciones',
          value: '${investigations.length}',
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.public,
          label: 'Fuentes analizadas',
          value: '$totalSources',
          color: AppColors.success,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.article_outlined,
          label: 'Hallazgos',
          value: '$totalFindings',
          color: AppColors.violet,
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (widget.controller.loading && widget.controller.investigations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final investigations = widget.controller.investigations;
    if (investigations.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open,
        title: 'Aún no hay investigaciones',
        message:
            'Crea una investigación para comenzar a registrar fuentes, '
            'hallazgos y generar informes.',
        action: FilledButton.icon(
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add),
          label: const Text('Crear la primera'),
        ),
      );
    }

    return ListView.separated(
      itemCount: investigations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final investigation = investigations[index];
        return _InvestigationCard(
          investigation: investigation,
          onOpen: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => InvestigationDetailScreen(
                controller: widget.controller,
                investigationId: investigation.id,
              ),
            ),
          ),
          onDelete: () => _confirmDelete(investigation),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestigationCard extends StatelessWidget {
  final Investigation investigation;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _InvestigationCard({
    required this.investigation,
    required this.onOpen,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (investigation.status) {
      case InvestigationStatus.draft:
        return AppColors.textMuted;
      case InvestigationStatus.inProgress:
        return AppColors.primary;
      case InvestigationStatus.completed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          investigation.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.text),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(
                        label: investigation.status.label,
                        color: _statusColor,
                        icon: investigation.status == InvestigationStatus.completed
                            ? Icons.check_circle_outline
                            : Icons.timelapse,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    investigation.objective.isEmpty
                        ? 'Sin objetivo definido.'
                        : investigation.objective,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.public,
                          size: 13, color: AppColors.textMuted),
                      Text(
                        '${investigation.sources.length} fuentes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Icon(Icons.article_outlined,
                          size: 13, color: AppColors.textMuted),
                      Text(
                        '${investigation.findings.length} hallazgos',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Icon(Icons.schedule,
                          size: 13, color: AppColors.textMuted),
                      Text(
                        'Actualizada ${investigation.updatedAt.day.toString().padLeft(2, '0')}/${investigation.updatedAt.month.toString().padLeft(2, '0')}/${investigation.updatedAt.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
