import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/relationship.dart';

/// Vista de árbol genealógico centrada en el perfil objetivo.
///
/// Organiza a las personas registradas por generación relativa al
/// objetivo (ascendientes arriba, descendientes abajo) y conecta las
/// generaciones con líneas estilizadas que crecen desde la figura
/// central.
class FamilyTreeView extends StatelessWidget {
  final String targetName;
  final String? targetPhotoBase64;
  final List<Relationship> relationships;

  const FamilyTreeView({
    super.key,
    required this.targetName,
    this.targetPhotoBase64,
    required this.relationships,
  });

  @override
  Widget build(BuildContext context) {
    final levels = <_TreeLevel>[
      _TreeLevel(
        label: 'Abuelos',
        members: _membersOf(group: {RelationshipType.grandfather, RelationshipType.grandmother}),
      ),
      _TreeLevel(
        label: 'Padres y tíos',
        members: _membersOf(group: {
          RelationshipType.father,
          RelationshipType.mother,
          RelationshipType.uncle,
          RelationshipType.aunt,
        }),
      ),
      _TreeLevel(
        label: 'Generación del objetivo',
        members: _membersOf(group: {
          RelationshipType.brother,
          RelationshipType.sister,
          RelationshipType.cousin,
          RelationshipType.spouse,
          RelationshipType.partner,
          RelationshipType.exPartner,
          RelationshipType.friend,
          RelationshipType.colleague,
          RelationshipType.other,
        }),
      ),
      _TreeLevel(
        label: 'Hijos y sobrinos',
        members: _membersOf(group: {
          RelationshipType.son,
          RelationshipType.daughter,
          RelationshipType.nephew,
          RelationshipType.niece,
        }),
      ),
      _TreeLevel(
        label: 'Nietos',
        members: _membersOf(group: {
          RelationshipType.grandson,
          RelationshipType.granddaughter,
        }),
      ),
    ];

    final visible = levels.where((level) => level.members.isNotEmpty).toList();
    final targetIndex =
        visible.indexWhere((level) => level.label == 'Generación del objetivo');
    if (targetIndex < 0) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i != 0) const _TreeConnector(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    visible[i].label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (i == targetIndex)
                      _TreeNode(
                        name: targetName.isEmpty ? 'Persona objetivo' : targetName,
                        role: 'Perfil objetivo',
                        photoBase64: targetPhotoBase64,
                        isTarget: true,
                      ),
                    for (final member in visible[i].members)
                      _TreeNode(
                        name: member.name,
                        role: member.type.label,
                        photoBase64: member.photoBase64,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Relationship> _membersOf({required Set<RelationshipType> group}) {
    return relationships
        .where((relationship) => group.contains(relationship.type))
        .toList();
  }
}

class _TreeLevel {
  final String label;
  final List<Relationship> members;

  const _TreeLevel({required this.label, required this.members});
}

/// Conector estilizado entre generaciones: tronco con ramas.
class _TreeConnector extends StatelessWidget {
  const _TreeConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 26,
      child: CustomPaint(painter: _ConnectorPainter()),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;

    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);

    final branchPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 16, size.height / 2),
      Offset(centerX + 16, size.height / 2),
      branchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Nodo visual de una persona dentro del árbol.
class _TreeNode extends StatelessWidget {
  final String name;
  final String role;
  final String? photoBase64;
  final bool isTarget;

  const _TreeNode({
    required this.name,
    required this.role,
    this.photoBase64,
    this.isTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isTarget ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTarget ? AppColors.primary : AppColors.border,
          width: isTarget ? 1.6 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: SizedBox(
              width: 40,
              height: 40,
              child: _avatar(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isTarget ? AppColors.primary : AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final photo = photoBase64;
    if (photo != null && photo.isNotEmpty) {
      return Image.memory(
        base64Decode(photo),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline,
        size: 22,
        color: isTarget ? AppColors.primary : AppColors.textMuted,
      ),
    );
  }
}