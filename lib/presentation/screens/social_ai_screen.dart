import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/investigation.dart';
import '../../domain/entities/social_link.dart';
import '../../domain/entities/source.dart';
import '../controllers/investigation_controller.dart';
import '../screens/settings_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/finding_tile.dart';

/// Pantalla de análisis con IA de contenido público de redes sociales.
class SocialAiScreen extends StatefulWidget {
  final InvestigationController controller;
  final Investigation? investigation;

  const SocialAiScreen({
    super.key,
    required this.controller,
    this.investigation,
  });

  @override
  State<SocialAiScreen> createState() => _SocialAiScreenState();
}

class _SocialAiScreenState extends State<SocialAiScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  SocialPlatform _platform = SocialPlatform.instagram;
  AnalysisResult? _result;
  String? _inputError;
  bool _analyzing = false;

  @override
  void dispose() {
    _urlController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(
        () => _inputError = 'Pega el contenido público que quieras analizar.',
      );
      return;
    }

    setState(() {
      _analyzing = true;
      _inputError = null;
      _result = null;
    });

    final result = await widget.controller.analyzeSocial(
      platform: _platform.label,
      content: content,
      url: _urlController.text.trim(),
    );

    if (!mounted) return;
    if (result == null) {
      setState(() => _analyzing = false);
      _showSnackBar(
        widget.controller.error ??
            'No se pudo analizar el contenido. Revisá tu API key.',
      );
      return;
    }
    setState(() {
      _analyzing = false;
      _result = result;
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

    _showSnackBar('Análisis IA guardado en la investigación.');
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
          builder: (_) => SocialAiScreen(
            controller: widget.controller,
            investigation: created,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.investigation == null ? 'Análisis con IA' : 'Análisis con IA',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (!widget.controller.hasAiKey)
                  _buildApiKeyBanner(context),
                _buildHelpCard(context),
                const SizedBox(height: 20),
                _buildInput(context),
                const SizedBox(height: 20),
                _buildResult(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No hay ninguna API key de IA configurada. Agregá al menos un '
              'proveedor para usar el análisis.',
              style: TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SettingsScreen(controller: widget.controller),
                ),
              );
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    final controller = widget.controller;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          leading: Icon(Icons.lightbulb_outline, color: AppColors.violet),
          title: const Text(
            '¿Qué hace este análisis con IA?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'El analizador estructura hallazgos a partir del contenido público '
            'que vos aportás (bio, publicaciones o capturas de texto de un '
            'perfil). Genera un resumen objetivo y hallazgos categorizados, '
            'cada uno con su nivel de confianza y la evidencia encontrada.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 12),
          const _HelpItem(
            icon: Icons.text_snippet_outlined,
            text: 'Pegá el texto literal del perfil: mejor resultados con '
                'contenido real que con resúmenes.',
          ),
          const _HelpItem(
            icon: Icons.filter_alt_outlined,
            text: 'Elegí la plataforma y, si querés, la URL pública del perfil.',
          ),
          const _HelpItem(
            icon: Icons.verified_outlined,
            text: 'Revisá cada hallazgo: la confianza indica qué tan sólido es '
                'el dato según la evidencia aportada.',
          ),
          const _HelpItem(
            icon: Icons.no_accounts_outlined,
            text: 'No accede a perfiles privados, no inicia sesión en ninguna '
                'red ni inventa datos. Solo trabaja con lo que pegás.',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.hasAiKey
                        ? 'Proveedor principal: ${controller.aiProviderLabel} · '
                            '${controller.aiFallbackEnabled ? 'fallback automático activado' : 'fallback desactivado'}'
                        : 'Sin proveedores configurados. Andá a Ajustes para agregar tu clave.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text,
                    ),
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

  Widget _buildInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analizar perfil con IA',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'La IA estructura hallazgos a partir del contenido público que aportas '
          '(bio, publicaciones, capturas de texto). No accede a perfiles privados.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<SocialPlatform>(
          initialValue: _platform,
          decoration: const InputDecoration(labelText: 'Plataforma'),
          items: [
            for (final platform in SocialPlatform.values)
              DropdownMenuItem(
                value: platform,
                child: Text(platform.label),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _platform = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _urlController,
          enabled: !_analyzing,
          decoration: const InputDecoration(
            labelText: 'URL del perfil (opcional)',
            hintText: 'https://www.instagram.com/usuario',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentController,
          enabled: !_analyzing,
          minLines: 5,
          maxLines: 12,
          decoration: InputDecoration(
            labelText: 'Contenido público',
            hintText:
                'Pegá aquí la bio, descripción o publicaciones públicas del perfil…',
            alignLabelWithHint: true,
            errorText: _inputError,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _analyzing
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : FilledButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Analizar con IA'),
                ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    if (_analyzing) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analizando el contenido con IA…'),
            ],
          ),
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return const SizedBox(
        height: 220,
        child: EmptyState(
          icon: Icons.auto_awesome,
          title: 'Esperando contenido',
          message:
              'Pega el contenido público del perfil y presiona "Analizar con IA".',
        ),
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
        Text('Hallazgos (${result.findings.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (result.findings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('La IA no extrajo hallazgos.')),
          )
        else
          for (final finding in result.findings) ...[
            FindingTile(finding: finding),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

/// Ítem de ayuda con icono para la tarjeta explicativa.
class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
                  color: AppColors.violet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'IA',
                  style: TextStyle(
                    color: AppColors.violet,
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
            result.sourceType.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          if (result.providerLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Análisis asistido por ${result.providerLabel}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.violet,
                ),
              ),
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
