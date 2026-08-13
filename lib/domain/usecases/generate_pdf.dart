import 'dart:typed_data';

import '../entities/investigation.dart';

/// Documento de informe generado.
class ReportDocument {
  final Uint8List bytes;
  final String fileName;

  const ReportDocument({required this.bytes, required this.fileName});
}

/// Contrato para generadores de informes estructurados.
abstract class ReportGenerator {
  Future<ReportDocument> generate(Investigation investigation);
}

/// Caso de uso: generar el informe PDF de una investigación.
class GeneratePdf {
  final ReportGenerator _generator;

  const GeneratePdf(this._generator);

  Future<ReportDocument> call(Investigation investigation) =>
      _generator.generate(investigation);
}
