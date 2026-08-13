import '../../domain/entities/relationship.dart';

/// Serialización JSON de un [Relationship].
class RelationshipModel {
  RelationshipModel._();

  static Relationship fromJson(Map<String, dynamic> json) {
    return Relationship(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      type: RelationshipType.values.asNameMap()[json['type']] ??
          RelationshipType.other,
      notes: (json['notes'] as String?) ?? '',
      photoBase64: json['photoBase64'] as String?,
    );
  }

  static Map<String, dynamic> toJson(Relationship relationship) {
    return {
      'id': relationship.id,
      'name': relationship.name,
      'type': relationship.type.name,
      'notes': relationship.notes,
      if (relationship.photoBase64 != null)
        'photoBase64': relationship.photoBase64,
    };
  }
}
