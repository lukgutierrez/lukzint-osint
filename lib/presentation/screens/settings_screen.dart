import 'package:flutter/material.dart';

import '../../core/settings/ai_provider.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/investigation_controller.dart';

/// Pantalla de ajustes: configuración del proveedor de IA, claves y
/// fallback automático entre proveedores gratuitos.
class SettingsScreen extends StatefulWidget {
  final InvestigationController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saving = false;

  Future<void> _saveProvider(AiProvider provider, String apiKey) async {
    setState(() => _saving = true);
    final ok = await widget.controller.saveApiKey(provider, apiKey);
    if (!mounted) return;
    setState(() => _saving = false);
    _showSnackBar(
      ok
          ? 'API key de ${provider.label} guardada.'
          : widget.controller.error ?? 'No se pudo guardar.',
    );
  }

  Future<void> _selectProvider(AiProvider provider) async {
    if (provider == widget.controller.aiProvider) return;
    final ok = await widget.controller.selectAiProvider(provider);
    if (!mounted) return;
    _showSnackBar(
      ok
          ? 'Proveedor principal: ${provider.label}.'
          : widget.controller.error ?? 'No se pudo cambiar el proveedor.',
    );
  }

  Future<void> _toggleFallback(bool enabled) async {
    await widget.controller.setAiFallbackEnabled(enabled);
    if (!mounted) return;
    _showSnackBar(
      enabled
          ? 'Fallback automático activado.'
          : 'Fallback automático desactivado.',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Análisis con IA',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LUKZINT usa proveedores de IA para estructurar los '
                      'hallazgos del contenido público que aportás. Configurá '
                      'al menos una clave; las claves se guardan únicamente en '
                      'tu dispositivo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    _buildProviderSelector(context),
                    const SizedBox(height: 12),
                    _buildFallbackToggle(context),
                    const SizedBox(height: 20),
                    Text(
                      'Claves de API',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cada proveedor tiene su propia clave. Completá los que '
                      'quieras usar: el principal se intenta primero y el '
                      'fallback prueba el resto si algo falla.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final provider in AiProvider.values) ...[
                      _ProviderKeyCard(
                        provider: provider,
                        controller: controller,
                        saving: _saving,
                        onSave: _saveProvider,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderSelector(BuildContext context) {
    final controller = widget.controller;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proveedor principal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AiProvider>(
            initialValue: controller.aiProvider,
            decoration: const InputDecoration(labelText: 'Proveedor de IA'),
            items: [
              for (final provider in AiProvider.values)
                DropdownMenuItem(
                  value: provider,
                  child: Text(provider.label),
                ),
            ],
            onChanged: (value) {
              if (value != null) _selectProvider(value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Actual: ${controller.aiProviderLabel}. '
            '${controller.aiProvider.description}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackToggle(BuildContext context) {
    final controller = widget.controller;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fallback automático'),
          subtitle: const Text(
            'Si el proveedor principal falla, intenta con los demás configurados.',
          ),
          value: controller.aiFallbackEnabled,
          onChanged: _toggleFallback,
          activeThumbColor: AppColors.primary,
          tileColor: Colors.transparent,
        ),
      ),
    );
  }
}

/// Tarjeta de configuración de la clave de un proveedor de IA.
class _ProviderKeyCard extends StatefulWidget {
  final AiProvider provider;
  final InvestigationController controller;
  final bool saving;
  final Future<void> Function(AiProvider provider, String apiKey) onSave;

  const _ProviderKeyCard({
    required this.provider,
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_ProviderKeyCard> createState() => _ProviderKeyCardState();
}

class _ProviderKeyCardState extends State<_ProviderKeyCard> {
  late final TextEditingController _apiKeyController;
  bool _obscure = true;
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController =
        TextEditingController(text: widget.controller.apiKeyFor(widget.provider) ?? '');
    _configured = widget.controller.hasApiKey(widget.provider);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.onSave(widget.provider, _apiKeyController.text);
    if (!mounted) return;
    setState(() => _configured = widget.controller.hasApiKey(widget.provider));
  }

  String get _setupHint => switch (widget.provider) {
        AiProvider.gemini => 'Obtené tu clave en https://aistudio.google.com '
            '("Get API key" → "Create API key"). Plan gratuito disponible.',
        AiProvider.openrouter => 'Obtené tu clave en https://openrouter.ai/keys '
            'con tu cuenta. Modelos :free sin tarjeta.',
        AiProvider.groq => 'Obtené tu clave en https://console.groq.com/keys. '
            'Plan gratuito sin tarjeta.',
        AiProvider.mistral => 'Obtené tu clave en https://console.mistral.ai '
            '(API keys → Create). Modo gratuito sin tarjeta.',
      };

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _configured ? AppColors.success : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(configured: _configured),
              const SizedBox(width: 8),
              Icon(_iconFor(provider), size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            provider.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API key de ${provider.label}',
              hintText: provider == AiProvider.gemini ? 'AIza...' : 'sk-or-v1-...',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: widget.saving
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            _setupHint,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AiProvider provider) {
    switch (provider) {
      case AiProvider.gemini:
        return Icons.auto_awesome;
      case AiProvider.openrouter:
        return Icons.route_outlined;
      case AiProvider.groq:
        return Icons.bolt_outlined;
      case AiProvider.mistral:
        return Icons.air;
    }
  }
}

class _StatusDot extends StatelessWidget {
  final bool configured;

  const _StatusDot({required this.configured});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: configured ? AppColors.success : AppColors.border,
      ),
    );
  }
}