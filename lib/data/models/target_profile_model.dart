import '../../domain/entities/target_profile.dart';

/// Serialización JSON de un [TargetProfile].
class TargetProfileModel {
  TargetProfileModel._();

  static TargetProfile fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TargetProfile();
    return TargetProfile(
      fullName: (json['fullName'] as String?) ?? '',
      dni: (json['dni'] as String?) ?? '',
      cuit: (json['cuit'] as String?) ?? '',
      alias: (json['alias'] as String?) ?? '',
      birthDate: (json['birthDate'] as String?) ?? '',
      age: (json['age'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      coordinates: (json['coordinates'] as String?) ?? '',
      occupation: (json['occupation'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      phoneCarrier: (json['phoneCarrier'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      photoBase64: json['photoBase64'] as String?,
    );
  }

  static Map<String, dynamic> toJson(TargetProfile profile) {
    return {
      'fullName': profile.fullName,
      'dni': profile.dni,
      'cuit': profile.cuit,
      'alias': profile.alias,
      'birthDate': profile.birthDate,
      'age': profile.age,
      'location': profile.location,
      'coordinates': profile.coordinates,
      'occupation': profile.occupation,
      'phone': profile.phone,
      'phoneCarrier': profile.phoneCarrier,
      'email': profile.email,
      'notes': profile.notes,
      if (profile.photoBase64 != null) 'photoBase64': profile.photoBase64,
    };
  }
}