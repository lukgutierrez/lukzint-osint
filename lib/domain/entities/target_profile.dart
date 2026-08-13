/// Perfil de la persona objetivo de una investigación OSINT.
///
/// Solo contiene datos que el propio usuario ingresa de forma manual,
/// a partir de información pública que decide registrar. La foto se
/// almacena codificada en base64 para que viaje junto con el resto de
/// los datos y pueda incluirse en los informes.
class TargetProfile {
  final String fullName;
  final String dni;
  final String cuit;
  final String alias;
  final String birthDate;
  final String age;
  final String location;
  final String coordinates;
  final String occupation;
  final String phone;
  final String phoneCarrier;
  final String email;
  final String notes;
  final String? photoBase64;

  const TargetProfile({
    this.fullName = '',
    this.dni = '',
    this.cuit = '',
    this.alias = '',
    this.birthDate = '',
    this.age = '',
    this.location = '',
    this.coordinates = '',
    this.occupation = '',
    this.phone = '',
    this.phoneCarrier = '',
    this.email = '',
    this.notes = '',
    this.photoBase64,
  });

  bool get isEmpty =>
      fullName.isEmpty &&
      dni.isEmpty &&
      cuit.isEmpty &&
      alias.isEmpty &&
      birthDate.isEmpty &&
      age.isEmpty &&
      location.isEmpty &&
      coordinates.isEmpty &&
      occupation.isEmpty &&
      phone.isEmpty &&
      phoneCarrier.isEmpty &&
      email.isEmpty &&
      notes.isEmpty &&
      photoBase64 == null;

  TargetProfile copyWith({
    String? fullName,
    String? dni,
    String? cuit,
    String? alias,
    String? birthDate,
    String? age,
    String? location,
    String? coordinates,
    String? occupation,
    String? phone,
    String? phoneCarrier,
    String? email,
    String? notes,
    String? photoBase64,
  }) {
    return TargetProfile(
      fullName: fullName ?? this.fullName,
      dni: dni ?? this.dni,
      cuit: cuit ?? this.cuit,
      alias: alias ?? this.alias,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      occupation: occupation ?? this.occupation,
      phone: phone ?? this.phone,
      phoneCarrier: phoneCarrier ?? this.phoneCarrier,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }
}