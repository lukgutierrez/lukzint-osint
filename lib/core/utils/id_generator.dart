import 'dart:math';

/// Genera un identificador único razonablemente seguro combinando
/// el timestamp actual con bytes aleatorios.
String generateId() {
  final rand = Random.secure();
  final now = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  final randomPart = List.generate(
    8,
    (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$now-$randomPart';
}
