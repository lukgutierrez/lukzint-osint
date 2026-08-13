import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/investigation.dart';
import '../../domain/entities/relationship.dart';
import '../../domain/entities/social_link.dart';
import '../../domain/entities/target_profile.dart';
import '../controllers/investigation_controller.dart';
import '../screens/analyzer_screen.dart';
import '../screens/pdf_preview_screen.dart';
import '../screens/social_ai_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/family_tree_view.dart';
import '../widgets/finding_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/source_tile.dart';
import '../widgets/status_badge.dart';

/// Pantalla de detalle de una investigación.
class InvestigationDetailScreen extends StatefulWidget {
  final InvestigationController controller;
  final String investigationId;

  const InvestigationDetailScreen({
    super.key,
    required this.controller,
    required this.investigationId,
  });

  @override
  State<InvestigationDetailScreen> createState() =>
      _InvestigationDetailScreenState();
}

class _InvestigationDetailScreenState extends State<InvestigationDetailScreen> {
  bool _generatingPdf = false;
  bool _showFamilyTree = false;

  Investigation get _investigation {
    for (final inv in widget.controller.investigations) {
      if (inv.id == widget.investigationId) return inv;
    }
    return _fallback;
  }

  late final Investigation _fallback;

  @override
  void initState() {
    super.initState();
    _fallback = Investigation.create(title: 'Cargando…', objective: '');
  }

  Future<void> _generatePdf(Investigation investigation) async {
    setState(() => _generatingPdf = true);
    final report =
        await widget.controller.generatePdfReport(investigation);
    if (!mounted) return;
    setState(() => _generatingPdf = false);

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.error ?? 'Error al generar PDF')),
      );
      return;
    }

    try {
      await Printing.sharePdf(bytes: report.bytes, filename: report.fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo compartir el PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final investigation = _investigation;
            return LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth > 1400
                    ? 1400.0
                    : constraints.maxWidth;
                final isNarrow = constraints.maxWidth < 760;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppBar(context, investigation, isNarrow),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: constraints.maxWidth >= 1100
                                ? _buildWideLayout(context, investigation)
                                : _buildNarrowLayout(context, investigation),
                          ),
                        ),
                      ],
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

  Widget _buildAppBar(
    BuildContext context,
    Investigation investigation,
    bool isNarrow,
  ) {
    final backButton = IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Volver',
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                investigation.title,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            StatusBadge(
              label: investigation.status.label,
              color: investigation.status == InvestigationStatus.completed
                  ? AppColors.success
                  : AppColors.primary,
              icon: investigation.status == InvestigationStatus.completed
                  ? Icons.check_circle_outline
                  : Icons.timelapse,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${investigation.sourceCount} fuentes · ${investigation.findingCount} hallazgos · '
          'Creada ${investigation.createdAt.day.toString().padLeft(2, '0')}/${investigation.createdAt.month.toString().padLeft(2, '0')}/${investigation.createdAt.year}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );

    final analyzeButton = OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AnalyzerScreen(
              controller: widget.controller,
              investigation: investigation,
            ),
          ),
        );
      },
      icon: const Icon(Icons.travel_explore),
      label: const Text('Analizar URL'),
    );

    final pdfButton = _generatingPdf
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : FilledButton.icon(
            onPressed: () => _generatePdf(investigation),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Generar PDF'),
          );

    final previewButton = OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PdfPreviewScreen(
              controller: widget.controller,
              investigation: investigation,
            ),
          ),
        );
      },
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('Ver PDF'),
    );

    if (isNarrow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                backButton,
                const SizedBox(width: 4),
                Expanded(child: titleBlock),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  analyzeButton,
                  previewButton,
                  pdfButton,
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          backButton,
          const SizedBox(width: 4),
          Expanded(child: titleBlock),
          const SizedBox(width: 16),
          analyzeButton,
          const SizedBox(width: 12),
          previewButton,
          const SizedBox(width: 12),
          pdfButton,
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, Investigation investigation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildObjectiveCard(context, investigation),
                const SizedBox(height: 20),
                _buildTargetSection(context, investigation),
                const SizedBox(height: 20),
                _buildSocialLinksSection(context, investigation),
                const SizedBox(height: 20),
                _buildAiSection(context, investigation),
                const SizedBox(height: 20),
                _buildRelationshipsSection(context, investigation),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Fuentes analizadas',
                  subtitle: '${investigation.sources.length} registradas',
                ),
                const SizedBox(height: 12),
                ..._sourcesOrEmpty(context, investigation),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Hallazgos',
                subtitle: '${investigation.findings.length} registrados',
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildFindingsList(context, investigation)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Investigation investigation) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildObjectiveCard(context, investigation),
          const SizedBox(height: 20),
          _buildTargetSection(context, investigation),
          const SizedBox(height: 20),
          _buildSocialLinksSection(context, investigation),
          const SizedBox(height: 20),
          _buildAiSection(context, investigation),
          const SizedBox(height: 20),
          _buildRelationshipsSection(context, investigation),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Fuentes analizadas',
            subtitle: '${investigation.sources.length} registradas',
          ),
          const SizedBox(height: 12),
          ..._sourcesOrEmpty(context, investigation),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Hallazgos',
            subtitle: '${investigation.findings.length} registrados',
          ),
          const SizedBox(height: 12),
          ..._findingsOrEmpty(context, investigation),
        ],
      ),
    );
  }

  Widget _buildObjectiveCard(BuildContext context, Investigation investigation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_outlined, size: 16, color: AppColors.textMuted),
              SizedBox(width: 8),
              Text(
                'Objetivo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            investigation.objective.isEmpty
                ? 'No se definió un objetivo para esta investigación.'
                : investigation.objective,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection(
    BuildContext context,
    Investigation investigation,
  ) {
    final profile = investigation.targetProfile;
    final isEmpty = profile == null || profile.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Perfil objetivo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editTargetProfile(investigation),
                visualDensity: VisualDensity.compact,
                tooltip: 'Editar perfil',
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEmpty)
            _buildEmptyProfile(context, investigation)
          else
            _buildProfileContent(context, profile),
        ],
      ),
    );
  }  Widget _buildEmptyProfile(
    BuildContext context,
    Investigation investigation,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photoPlaceholder(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registra los datos y la foto de la persona objetivo.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _editTargetProfile(investigation),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Completar perfil'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent(BuildContext context, TargetProfile profile) {
    final photo = profile.photoBase64;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photo != null && photo.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(photo),
              width: 88,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _photoPlaceholder(),
            ),
          )
        else
          _photoPlaceholder(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileField('Nombre completo', profile.fullName),
              _profileField('DNI', profile.dni),
              _profileField('CUIT / CUIL', profile.cuit),
              _profileField('Alias', profile.alias),
              _profileField('Nacimiento', profile.birthDate),
              _profileField('Edad', profile.age),
              _profileField('Ubicación', profile.location),
              _profileField('Domicilio / Coordenadas', profile.coordinates),
              _profileField('Ocupación', profile.occupation),
              _profileField('Teléfono', profile.phone),
              _profileField('Compañía de línea', profile.phoneCarrier),
              _profileField('Correo electrónico', profile.email),
              if (profile.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  profile.notes,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (profile.isEmpty)
                const Text(
                  'Sin datos registrados.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileField(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 88,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.person_outline,
        size: 36,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildSocialLinksSection(
    BuildContext context,
    Investigation investigation,
  ) {
    final links = investigation.socialLinks;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.alternate_email,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Redes sociales',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addSocialLink(investigation),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (links.isEmpty)
            const Text(
              'Aún no hay redes sociales registradas.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final link in links)
                  _socialChip(context, investigation, link),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAiSection(
    BuildContext context,
    Investigation investigation,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.violet),
              SizedBox(width: 8),
              Text(
                'Análisis con IA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Analiza con IA el contenido público de perfiles de Instagram, TikTok, '
            'LinkedIn y otros. El analizador solo trabaja con la información '
            'pública que aportes.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SocialAiScreen(
                    controller: widget.controller,
                    investigation: investigation,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Abrir analizador IA'),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipsSection(
    BuildContext context,
    Investigation investigation,
  ) {
    final relationships = investigation.relationships;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.family_restroom,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Genealogía y relaciones',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addRelationship(investigation),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (relationships.isEmpty)
            const Text(
              'Aún no hay personas registradas en la red de relaciones.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _showFamilyTree = !_showFamilyTree),
                icon: Icon(
                  _showFamilyTree ? Icons.view_agenda_outlined : Icons.account_tree_outlined,
                  size: 18,
                ),
                label: Text(
                  _showFamilyTree ? 'Ver como lista' : 'Ver árbol genealógico',
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_showFamilyTree)
              FamilyTreeView(
                targetName: investigation.targetProfile?.fullName ?? '',
                targetPhotoBase64: investigation.targetProfile?.photoBase64,
                relationships: relationships,
              )
            else
              ..._relationshipGroups(context, investigation),
          ],
        ],
      ),
    );
  }

  List<Widget> _relationshipGroups(
    BuildContext context,
    Investigation investigation,
  ) {
    const groups = ['Familia', 'Pareja', 'Amigos', 'Colegas', 'Otros'];
    final widgets = <Widget>[];
    for (final group in groups) {
      final members = investigation.relationships
          .where((r) => r.type.group == group)
          .toList();
      if (members.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            group,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 6));
      widgets.add(
        Column(
          children: [
            for (final member in members)
              _relationshipRow(context, investigation, member),
          ],
        ),
      );
    }
    return widgets;
  }

  Widget _relationshipRow(
    BuildContext context,
    Investigation investigation,
    Relationship relationship,
  ) {
    final photo = relationship.photoBase64;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (photo != null && photo.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(photo),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _personAvatar(),
              ),
            )
          else
            _personAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relationship.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (relationship.type.label.isNotEmpty ||
                    relationship.notes.isNotEmpty)
                  Text(
                    relationship.notes.isEmpty
                        ? relationship.type.label
                        : '${relationship.type.label} · ${relationship.notes}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editRelationship(investigation, relationship),
            visualDensity: VisualDensity.compact,
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.primary),
          ),
          IconButton(
            onPressed: () => _removeRelationship(investigation, relationship),
            visualDensity: VisualDensity.compact,
            tooltip: 'Quitar',
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  Widget _personAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.person_outline,
        size: 22,
        color: AppColors.textMuted,
      ),
    );
  }

  Future<void> _addRelationship(Investigation investigation) async {
    final result = await showDialog<Relationship>(
      context: context,
      builder: (_) => const _RelationshipDialog(),
    );
    if (result == null) return;
    await _saveInvestigation(
      investigation.copyWith(
        relationships: [...investigation.relationships, result],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _editRelationship(
    Investigation investigation,
    Relationship relationship,
  ) async {
    final result = await showDialog<Relationship>(
      context: context,
      builder: (_) => _RelationshipDialog(initial: relationship),
    );
    if (result == null) return;
    await _saveInvestigation(
      investigation.copyWith(
        relationships: [
          for (final r in investigation.relationships)
            if (r.id == relationship.id) result else r,
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _removeRelationship(
    Investigation investigation,
    Relationship relationship,
  ) async {
    await _saveInvestigation(
      investigation.copyWith(
        relationships: investigation.relationships
            .where((r) => r.id != relationship.id)
            .toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Widget _socialChip(
    BuildContext context,
    Investigation investigation,
    SocialLink link,
  ) {
    return InputChip(
      avatar: Icon(_platformIcon(link.platform), size: 16),
      label: Text(
        link.username.isEmpty ? link.platform.label : link.username,
      ),
      tooltip: link.url,
      onPressed: () => _editSocialLink(investigation, link),
      onDeleted: () => _removeSocialLink(investigation, link),
      deleteButtonTooltipMessage: 'Quitar',
    );
  }

  IconData _platformIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.instagram:
        return Icons.photo_camera_outlined;
      case SocialPlatform.tiktok:
        return Icons.music_note_outlined;
      case SocialPlatform.facebook:
        return Icons.thumb_up_outlined;
      case SocialPlatform.linkedin:
        return Icons.work_outline;
      case SocialPlatform.x:
        return Icons.tag;
      case SocialPlatform.youtube:
        return Icons.play_circle_outline;
      case SocialPlatform.github:
        return Icons.code;
      case SocialPlatform.other:
        return Icons.link;
    }
  }

  Future<void> _editTargetProfile(Investigation investigation) async {
    final result = await showDialog<TargetProfile>(
      context: context,
      builder: (_) =>
          _TargetProfileDialog(initial: investigation.targetProfile),
    );
    if (result == null) return;
    await _saveInvestigation(
      investigation.copyWith(
        targetProfile: result,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _addSocialLink(Investigation investigation) async {
    final result = await showDialog<SocialLink>(
      context: context,
      builder: (_) => const _SocialLinkDialog(),
    );
    if (result == null) return;
    await _saveInvestigation(
      investigation.copyWith(
        socialLinks: [...investigation.socialLinks, result],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _editSocialLink(
    Investigation investigation,
    SocialLink link,
  ) async {
    final result = await showDialog<SocialLink>(
      context: context,
      builder: (_) => _SocialLinkDialog(initial: link),
    );
    if (result == null) return;
    await _saveInvestigation(
      investigation.copyWith(
        socialLinks: [
          for (final l in investigation.socialLinks)
            if (l.id == link.id) result else l,
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _removeSocialLink(
    Investigation investigation,
    SocialLink link,
  ) async {
    await _saveInvestigation(
      investigation.copyWith(
        socialLinks: investigation.socialLinks
            .where((l) => l.id != link.id)
            .toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _saveInvestigation(Investigation updated) async {
    final ok = await widget.controller.updateInvestigation(updated);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.controller.error ?? 'No se pudieron guardar los cambios.'),
        ),
      );
    }
  }

  List<Widget> _sourcesOrEmpty(BuildContext context, Investigation investigation) {
    if (investigation.sources.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Aún no hay fuentes registradas. Usa "Analizar URL".',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      ];
    }
    return [
      for (final source in investigation.sources)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SourceTile(source: source),
        ),
    ];
  }

  List<Widget> _findingsOrEmpty(BuildContext context, Investigation investigation) {
    if (investigation.findings.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Aún no hay hallazgos registrados.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      ];
    }
    return [
      for (final finding in investigation.findings)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FindingTile(finding: finding),
        ),
    ];
  }

  Widget _buildFindingsList(BuildContext context, Investigation investigation) {
    if (investigation.findings.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        title: 'Sin hallazgos',
        message: 'Los hallazgos extraídos aparecerán aquí.',
      );
    }

    return ListView.separated(
      itemCount: investigation.findings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          FindingTile(finding: investigation.findings[index]),
    );
  }
}

/// Diálogo para registrar o editar el perfil de la persona objetivo.
class _TargetProfileDialog extends StatefulWidget {
  final TargetProfile? initial;

  const _TargetProfileDialog({this.initial});

  @override
  State<_TargetProfileDialog> createState() => _TargetProfileDialogState();
}

class _TargetProfileDialogState extends State<_TargetProfileDialog> {
  late final TextEditingController _fullName;
  late final TextEditingController _dni;
  late final TextEditingController _cuit;
  late final TextEditingController _alias;
  late final TextEditingController _birthDate;
  late final TextEditingController _age;
  late final TextEditingController _location;
  late final TextEditingController _coordinates;
  late final TextEditingController _occupation;
  late final TextEditingController _phone;
  late final TextEditingController _phoneCarrier;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  Uint8List? _photoBytes;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? const TargetProfile();
    _fullName = TextEditingController(text: initial.fullName);
    _dni = TextEditingController(text: initial.dni);
    _cuit = TextEditingController(text: initial.cuit);
    _alias = TextEditingController(text: initial.alias);
    _birthDate = TextEditingController(text: initial.birthDate);
    _age = TextEditingController(text: initial.age);
    _location = TextEditingController(text: initial.location);
    _coordinates = TextEditingController(text: initial.coordinates);
    _occupation = TextEditingController(text: initial.occupation);
    _phone = TextEditingController(text: initial.phone);
    _phoneCarrier = TextEditingController(text: initial.phoneCarrier);
    _email = TextEditingController(text: initial.email);
    _notes = TextEditingController(text: initial.notes);
    if (initial.photoBase64 != null && initial.photoBase64!.isNotEmpty) {
      _photoBytes = base64Decode(initial.photoBase64!);
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _dni.dispose();
    _cuit.dispose();
    _alias.dispose();
    _birthDate.dispose();
    _age.dispose();
    _location.dispose();
    _coordinates.dispose();
    _occupation.dispose();
    _phone.dispose();
    _phoneCarrier.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _photoBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar la imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    final profile = TargetProfile(
      fullName: _fullName.text.trim(),
      dni: _dni.text.trim(),
      cuit: _cuit.text.trim(),
      alias: _alias.text.trim(),
      birthDate: _birthDate.text.trim(),
      age: _age.text.trim(),
      location: _location.text.trim(),
      coordinates: _coordinates.text.trim(),
      occupation: _occupation.text.trim(),
      phone: _phone.text.trim(),
      phoneCarrier: _phoneCarrier.text.trim(),
      email: _email.text.trim(),
      notes: _notes.text.trim(),
      photoBase64: _photoBytes == null ? null : base64Encode(_photoBytes!),
    );
    Navigator.pop(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Perfil objetivo'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: _picking ? null : _pickPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      if (_photoBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _photoBytes!,
                            height: 160,
                            width: 130,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 130,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _picking
                              ? const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                )
                              : const Icon(Icons.add_a_photo_outlined,
                                  size: 36, color: AppColors.textMuted),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toca para subir la foto de la persona',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _fullName,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  hintText: 'Ej. María Fernanda López',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _dni,
                decoration: const InputDecoration(
                  labelText: 'DNI',
                  hintText: 'Ej. 40.123.456',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cuit,
                decoration: const InputDecoration(
                  labelText: 'CUIT / CUIL',
                  hintText: 'Ej. 20-40123456-7',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _birthDate,
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  hintText: 'Ej. 15/03/1990',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono / Celular',
                  hintText: 'Ej. +54 9 11 5555-1234',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneCarrier,
                decoration: const InputDecoration(
                  labelText: 'Compañía de la línea',
                  hintText: 'Ej. Movistar, Claro, Personal',
                  prefixIcon: Icon(Icons.perm_device_information_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'Ej. usuario@correo.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _coordinates,
                decoration: const InputDecoration(
                  labelText: 'Domicilio / Coordenadas',
                  hintText: 'Ej. -34.6037, -58.3816 o dirección',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _alias,
                decoration: const InputDecoration(
                  labelText: 'Alias / Usuario',
                  hintText: 'Ej. @mflopez',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  hintText: 'Ej. Buenos Aires, Argentina',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _occupation,
                decoration: const InputDecoration(
                  labelText: 'Ocupación / Organización',
                  hintText: 'Ej. Periodista en medio público',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _age,
                decoration: const InputDecoration(
                  labelText: 'Edad (opcional)',
                  hintText: 'Ej. 32',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Datos adicionales que quieras registrar',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Diálogo para agregar o editar un enlace de red social.
class _SocialLinkDialog extends StatefulWidget {
  final SocialLink? initial;

  const _SocialLinkDialog({this.initial});

  @override
  State<_SocialLinkDialog> createState() => _SocialLinkDialogState();
}

class _SocialLinkDialogState extends State<_SocialLinkDialog> {
  late SocialPlatform _platform;
  late final TextEditingController _url;
  late final TextEditingController _username;

  @override
  void initState() {
    super.initState();
    _platform = widget.initial?.platform ?? SocialPlatform.instagram;
    _url = TextEditingController(text: widget.initial?.url ?? '');
    _username = TextEditingController(text: widget.initial?.username ?? '');
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    super.dispose();
  }

  void _save() {
    final url = _url.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce la URL del perfil.')),
      );
      return;
    }
    Navigator.pop(
      context,
      SocialLink(
        id: widget.initial?.id ?? generateId(),
        platform: _platform,
        url: url,
        username: _username.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Agregar red social' : 'Editar red social',
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 14),
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Usuario (opcional)',
                hintText: 'Ej. mflopez',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: 'URL del perfil',
                hintText: 'https://www.instagram.com/mflopez',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Diálogo para registrar o editar una persona de la red de relaciones.
class _RelationshipDialog extends StatefulWidget {
  final Relationship? initial;

  const _RelationshipDialog({this.initial});

  @override
  State<_RelationshipDialog> createState() => _RelationshipDialogState();
}

class _RelationshipDialogState extends State<_RelationshipDialog> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late RelationshipType _type;
  Uint8List? _photoBytes;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _notes = TextEditingController(text: initial?.notes ?? '');
    _type = initial?.type ?? RelationshipType.father;
    if (initial?.photoBase64 != null && initial!.photoBase64!.isNotEmpty) {
      _photoBytes = base64Decode(initial.photoBase64!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _photoBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar la imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el nombre de la persona.')),
      );
      return;
    }
    Navigator.pop(
      context,
      Relationship(
        id: widget.initial?.id ?? generateId(),
        name: name,
        type: _type,
        notes: _notes.text.trim(),
        photoBase64: _photoBytes == null ? null : base64Encode(_photoBytes!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Agregar persona' : 'Editar persona',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: _picking ? null : _pickPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      if (_photoBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _photoBytes!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _picking
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                )
                              : const Icon(Icons.person_add_alt_1,
                                  size: 32, color: AppColors.textMuted),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toca para subir foto (opcional)',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Nombre o apodo de la persona',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<RelationshipType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Vínculo'),
                items: [
                  for (final type in RelationshipType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text('${type.group} · ${type.label}'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Datos adicionales (opcional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
