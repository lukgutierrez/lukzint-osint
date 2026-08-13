/// Tipo de vínculo de una persona en la red de relaciones.
enum RelationshipType {
  grandfather,
  grandmother,
  father,
  mother,
  uncle,
  aunt,
  brother,
  sister,
  cousin,
  spouse,
  partner,
  exPartner,
  son,
  daughter,
  nephew,
  niece,
  grandson,
  granddaughter,
  friend,
  colleague,
  other,
}

extension RelationshipTypeLabel on RelationshipType {
  String get label => switch (this) {
        RelationshipType.grandfather => 'Abuelo',
        RelationshipType.grandmother => 'Abuela',
        RelationshipType.father => 'Padre',
        RelationshipType.mother => 'Madre',
        RelationshipType.uncle => 'Tío',
        RelationshipType.aunt => 'Tía',
        RelationshipType.brother => 'Hermano',
        RelationshipType.sister => 'Hermana',
        RelationshipType.cousin => 'Primo/a',
        RelationshipType.spouse => 'Cónyuge',
        RelationshipType.partner => 'Pareja',
        RelationshipType.exPartner => 'Ex pareja',
        RelationshipType.son => 'Hijo',
        RelationshipType.daughter => 'Hija',
        RelationshipType.nephew => 'Sobrino',
        RelationshipType.niece => 'Sobrina',
        RelationshipType.grandson => 'Nieto',
        RelationshipType.granddaughter => 'Nieta',
        RelationshipType.friend => 'Amigo/a',
        RelationshipType.colleague => 'Colega',
        RelationshipType.other => 'Otro',
      };
}

extension RelationshipTypeGroup on RelationshipType {
  String get group => switch (this) {
        RelationshipType.grandfather ||
        RelationshipType.grandmother ||
        RelationshipType.father ||
        RelationshipType.mother ||
        RelationshipType.uncle ||
        RelationshipType.aunt ||
        RelationshipType.brother ||
        RelationshipType.sister ||
        RelationshipType.cousin ||
        RelationshipType.son ||
        RelationshipType.daughter ||
        RelationshipType.nephew ||
        RelationshipType.niece ||
        RelationshipType.grandson ||
        RelationshipType.granddaughter =>
          'Familia',
        RelationshipType.spouse ||
        RelationshipType.partner ||
        RelationshipType.exPartner =>
          'Pareja',
        RelationshipType.friend => 'Amigos',
        RelationshipType.colleague => 'Colegas',
        RelationshipType.other => 'Otros',
      };
}

extension RelationshipTypeGeneration on RelationshipType {
  /// Generación relativa a la persona objetivo para la vista de árbol:
  /// negativa hacia ascendientes, positiva hacia descendientes y 0 para
  /// la misma generación (hermanos, primos, pareja, amigos, colegas).
  int get generation => switch (this) {
        RelationshipType.grandfather ||
        RelationshipType.grandmother =>
          -2,
        RelationshipType.father ||
        RelationshipType.mother ||
        RelationshipType.uncle ||
        RelationshipType.aunt =>
          -1,
        RelationshipType.brother ||
        RelationshipType.sister ||
        RelationshipType.cousin ||
        RelationshipType.spouse ||
        RelationshipType.partner ||
        RelationshipType.exPartner ||
        RelationshipType.friend ||
        RelationshipType.colleague ||
        RelationshipType.other =>
          0,
        RelationshipType.son ||
        RelationshipType.daughter ||
        RelationshipType.nephew ||
        RelationshipType.niece =>
          1,
        RelationshipType.grandson ||
        RelationshipType.granddaughter =>
          2,
      };
}

/// Persona vinculada al objetivo dentro de una investigación.
///
/// Representa la red de relaciones (genealogía, amigos, colegas) que
/// el usuario registra de forma manual con información pública. La foto
/// se almacena codificada en base64.
class Relationship {
  final String id;
  final String name;
  final RelationshipType type;
  final String notes;
  final String? photoBase64;

  const Relationship({
    required this.id,
    required this.name,
    required this.type,
    this.notes = '',
    this.photoBase64,
  });

  Relationship copyWith({
    String? name,
    RelationshipType? type,
    String? notes,
    String? photoBase64,
  }) {
    return Relationship(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }
}