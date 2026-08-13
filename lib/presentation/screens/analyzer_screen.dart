import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/investigation.dart';
import '../../domain/entities/source.dart';
import '../controllers/investigation_controller.dart';
import '../screens/investigation_detail_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/finding_tile.dart';

/// Pantalla de análisis de una URL pública.
class AnalyzerScreen extends StatefulWidget {
  final InvestigationController controller;
  final Investigation? investigation;

  const AnalyzerScreen({
    super.key,
    required this.controller,
    this.investigation,
  });

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  final TextEditingController _urlController = TextEditingController();
  AnalysisResult? _result;
  String? _inputError;
  bool _analyzing = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _inputError = 'Introduce una URL para analizar.');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _inputError = 'La URL debe comenzar con http:// o https://.');
      return;
    }

    setState(() {
      _analyzing = true;
      _inputError = null;
      _result = null;
    });

    final result = await widget.controller.preview(url);

    if (!mounted) return;
    setState(() {
      _analyzing = false;
      if (result != null) {
        _result = result;
      }
    });
  }

  Future<void> _saveToInvestigation(AnalysisResult result) async {
    final investigation = widget.investigation;
    if (investigation == null) return;

    final before = investigation.sourceCount;
    final updated = await widget.controller.attach(investigation, result);
    if (!mounted) return;

    if (updated == null) {
      _showSnackBar(widget.controller.error ?? 'No se pudo guardar la fuente.');
      return;
    }

    if (updated.sourceCount == before) {
      _showSnackBar('La URL ya fue registrada en esta investigación.');
      return;
    }

    _showSnackBar('Fuente guardada en la investigación.');
    Navigator.pop(context);
  }

  Future<void> _createInvestigationAndSave(AnalysisResult result) async {
    final titleController = TextEditingController();
    final objectiveController = TextEditingController();

    final created = await showDialog<Investigation>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Crear investigación con resultados'),
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
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final investigation = await widget.controller.create(
                title: title,
                objective: objectiveController.text.trim(),
              );
              if (investigation != null) {
                await widget.controller.attach(investigation, result);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, investigation);
                }
              }
            },
            child: const Text('Crear y guardar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (created != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => InvestigationDetailScreen(
            controller: widget.controller,
            investigationId: created.id,
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final investigation = widget.investigation;

    return Scaffold(
      appBar: AppBar(
        title: Text(investigation == null ? 'Analizador OSINT' : 'Analizar URL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInput(context),
                  const SizedBox(height: 20),
                  Expanded(child: _buildResult(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analizar una URL pública',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Se consultan páginas web generales (metadatos OpenGraph) y '
          'perfiles públicos de GitHub mediante su API oficial.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                autofocus: true,
                enabled: !_analyzing,
                onSubmitted: (_) => _analyze(),
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com o https://github.com/usuario',
                  errorText: _inputError,
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 54,
              child: _analyzing
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : FilledButton.icon(
                      onPressed: _analyze,
                      icon: const Icon(Icons.search),
                      label: const Text('Analizar'),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    if (_analyzing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Consultando la fuente pública...'),
          ],
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return EmptyState(
        icon: Icons.travel_explore,
        title: 'Esperando una URL',
        message:
            'Introduce una URL de una página web o de un perfil público de '
            'GitHub y presiona "Analizar".',
      );
    }

    final investigation = widget.investigation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultHeader(
          result: result,
          onSave: investigation != null
              ? () => _saveToInvestigation(result)
              : () => _createInvestigationAndSave(result),
          bound: investigation != null,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hallazgos (${result.findings.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (result.findings.isEmpty)
                const Expanded(
                  child: Center(child: Text('No se extrajeron hallazgos.')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: result.findings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        FindingTile(finding: result.findings[index]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onSave;
  final bool bound;

  const _ResultHeader({
    required this.result,
    required this.onSave,
    required this.bound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.sourceType.label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.text),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (result.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${result.url}  →  ${result.finalUrl}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontFamily: 'monospace',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: Icon(bound ? Icons.save_alt : Icons.folder_open),
              label: Text(bound ? 'Guardar en investigación' : 'Crear investigación'),
            ),
          ),
        ],
      ),
    );
  }
}
