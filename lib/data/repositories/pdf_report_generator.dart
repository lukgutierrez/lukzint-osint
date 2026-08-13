import 'dart:convert';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/branding.dart';
import '../../core/utils/confidence.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/finding.dart';
import '../../domain/entities/investigation.dart';
import '../../domain/entities/relationship.dart';
import '../../domain/entities/social_link.dart';
import '../../domain/entities/source.dart';
import '../../domain/entities/target_profile.dart';
import '../../domain/usecases/generate_pdf.dart';

/// Generador de informes PDF estructurados y profesionales.
class PdfReportGenerator implements ReportGenerator {
  @override
  Future<ReportDocument> generate(Investigation investigation) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        footer: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                AppBranding.watermark,
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (_) => _buildSections(investigation),
      ),
    );

    final bytes = await document.save();
    final safeTitle = investigation.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(' ', '_')
        .toLowerCase();
    final fileName =
        'informe_${safeTitle}_${DateFormatter.dateOnly(investigation.updatedAt)}.pdf';

    return ReportDocument(bytes: bytes, fileName: fileName);
  }

  List<pw.Widget> _buildSections(Investigation investigation) {
    return [
      _header(investigation),
      pw.SizedBox(height: 28),
      _sectionTitle('1. Resumen'),
      pw.SizedBox(height: 10),
      pw.Text(
        investigation.objective.isEmpty
            ? 'Análisis de información pública sobre "${investigation.title}".'
            : investigation.objective,
        style: const pw.TextStyle(fontSize: 11, height: 1.6, color: PdfColors.grey900),
      ),
      pw.SizedBox(height: 28),
      _sectionTitle('2. Perfil objetivo'),
      pw.SizedBox(height: 10),
      _targetProfile(investigation.targetProfile),
      pw.SizedBox(height: 28),
      _sectionTitle('3. Redes sociales'),
      pw.SizedBox(height: 10),
      _socialLinks(investigation.socialLinks),
      pw.SizedBox(height: 28),
      _sectionTitle('4. Red de relaciones'),
      pw.SizedBox(height: 10),
      _relationships(investigation.relationships),
      pw.SizedBox(height: 28),
      _sectionTitle('5. Fuentes analizadas'),
      pw.SizedBox(height: 10),
      _sourcesTable(investigation.sources),
      pw.SizedBox(height: 28),
      _sectionTitle('6. Hallazgos'),
      pw.SizedBox(height: 10),
      _findingsTable(investigation.findings),
      pw.SizedBox(height: 28),
      _sectionTitle('7. Evidencias'),
      pw.SizedBox(height: 10),
      _evidences(investigation.findings),
      pw.SizedBox(height: 28),
      _sectionTitle('8. URLs de origen'),
      pw.SizedBox(height: 10),
      _sourceUrls(investigation.sources),
      pw.SizedBox(height: 28),
      _sectionTitle('9. Limitaciones del análisis'),
      pw.SizedBox(height: 10),
      _limitations(),
      pw.SizedBox(height: 8),
      pw.Divider(color: PdfColors.grey300),
      pw.SizedBox(height: 8),
      pw.Text(
        'Informe generado por ${AppBranding.appName}. Documento generado el ${DateFormatter.dateTime(DateTime.now())}.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    ];
  }

  pw.Widget _targetProfile(TargetProfile? profile) {
    if (profile == null || profile.isEmpty) {
      return pw.Text(
        'No se registró un perfil objetivo para esta investigación.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    }

    final photo = profile.photoBase64;
    final fields = <pw.Widget>[];
    void addField(String label, String value) {
      if (value.isEmpty) return;
      fields.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$label: ',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.TextSpan(
                  text: value,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    addField('Nombre completo', profile.fullName);
    addField('DNI', profile.dni);
    addField('CUIT / CUIL', profile.cuit);
    addField('Alias', profile.alias);
    addField('Fecha de nacimiento', profile.birthDate);
    addField('Edad', profile.age);
    addField('Ubicación', profile.location);
    addField('Domicilio / Coordenadas', profile.coordinates);
    addField('Ocupación', profile.occupation);
    addField('Teléfono / Celular', profile.phone);
    addField('Compañía de línea', profile.phoneCarrier);
    addField('Correo electrónico', profile.email);
    if (profile.notes.isNotEmpty) {
      addField('Notas', profile.notes);
    }

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: fields.isEmpty
          ? [
              pw.Text(
                'Perfil registrado sin datos adicionales.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ]
          : fields,
    );

    if (photo == null || photo.isEmpty) {
      return content;
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(
            pw.MemoryImage(base64Decode(photo)),
            width: 96,
            height: 120,
            fit: pw.BoxFit.cover,
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(child: content),
      ],
    );
  }

  pw.Widget _relationships(List<Relationship> relationships) {
    if (relationships.isEmpty) {
      return pw.Text(
        'No se registraron personas en la red de relaciones.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    }

    const groups = ['Familia', 'Pareja', 'Amigos', 'Colegas', 'Otros'];
    final sections = <pw.Widget>[];
    for (final group in groups) {
      final members =
          relationships.where((r) => r.type.group == group).toList();
      if (members.isEmpty) continue;
      sections.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
          child: pw.Text(
            group,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
        ),
      );
      for (final member in members) {
        final photo = member.photoBase64;
        final label = member.notes.isEmpty
            ? member.type.label
            : '${member.type.label} · ${member.notes}';
        final row = pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (photo != null && photo.isNotEmpty)
              pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(
                  pw.MemoryImage(base64Decode(photo)),
                  width: 32,
                  height: 32,
                  fit: pw.BoxFit.cover,
                ),
              )
            else
              pw.Container(
                width: 32,
                height: 32,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: member.name,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    if (label.isNotEmpty)
                      pw.TextSpan(
                        text: ' — $label',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
        sections.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: row,
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sections,
    );
  }

  pw.Widget _socialLinks(List<SocialLink> links) {
    if (links.isEmpty) {
      return pw.Text(
        'No se registraron redes sociales.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    }
    final data = <List<dynamic>>[
      for (final link in links)
        [link.platform.label, link.username, link.url],
    ];
    return pw.TableHelper.fromTextArray(
      headers: const ['Plataforma', 'Usuario', 'URL'],
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellPadding: const pw.EdgeInsets.all(6),
      columnWidths: {
        0: pw.FixedColumnWidth(90),
        1: pw.FixedColumnWidth(110),
        2: pw.FlexColumnWidth(3),
      },
    );
  }

  pw.Widget _header(Investigation investigation) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 22, horizontal: 26),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            AppBranding.appName,
            style: pw.TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              color: PdfColors.lightBlue100,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Informe de investigación',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            investigation.title,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.blueGrey100),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _infoItem('Informe generado', DateFormatter.dateTime(DateTime.now())),
              _infoItem('Última consulta', DateFormatter.dateTime(investigation.updatedAt)),
              _infoItem('Fuentes', '${investigation.sources.length}'),
              _infoItem('Hallazgos', '${investigation.findings.length}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _infoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey200),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          width: 64,
          height: 3,
          decoration: const pw.BoxDecoration(
            color: PdfColors.lightBlue600,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
      ],
    );
  }

  pw.Widget _sourcesTable(List<Source> sources) {
    final data = <List<dynamic>>[
      for (final source in sources)
        [
          source.type.label,
          source.title.isEmpty ? source.url : source.title,
          source.url,
          source.status == SourceStatus.analyzed ? 'OK' : source.status.label,
          DateFormatter.dateTime(source.consultedAt),
        ],
    ];
    if (data.isEmpty) {
      data.add(['-', 'No hay fuentes registradas', '', '-', '-']);
    }

    return pw.TableHelper.fromTextArray(
      headers: const ['Tipo', 'Fuente', 'URL', 'Estado', 'Consulta'],
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellPadding: const pw.EdgeInsets.all(6),
      columnWidths: {
        0: pw.FixedColumnWidth(72),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(3),
        3: pw.FixedColumnWidth(52),
        4: pw.FixedColumnWidth(90),
      },
    );
  }

  pw.Widget _findingsTable(List<Finding> findings) {
    final data = <List<dynamic>>[];
    for (var i = 0; i < findings.length; i++) {
      final finding = findings[i];
      data.add([
        '${i + 1}',
        finding.category.label,
        finding.description,
        finding.content,
        '${confidenceLabel(finding.confidence)} (${(finding.confidence * 100).round()}%)',
      ]);
    }
    if (data.isEmpty) {
      data.add(['-', 'No hay hallazgos registrados', '', '', '']);
    }

    return pw.TableHelper.fromTextArray(
      headers: const ['#', 'Categoría', 'Hallazgo', 'Contenido', 'Confianza'],
      data: data,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellPadding: const pw.EdgeInsets.all(6),
      columnWidths: {
        0: pw.FixedColumnWidth(26),
        1: pw.FixedColumnWidth(70),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(3),
        4: pw.FixedColumnWidth(66),
      },
    );
  }

  pw.Widget _evidences(List<Finding> findings) {
    final items = <pw.Widget>[];
    var index = 1;
    for (final finding in findings) {
      final evidence = finding.evidence;
      if (evidence == null || evidence.trim().isEmpty) continue;
      items.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '[$index]',
                style: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey600,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  '${finding.description}: $evidence',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    }
    if (items.isEmpty) {
      items.add(
        pw.Text(
          'No se registraron evidencias para esta investigación.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  pw.Widget _sourceUrls(List<Source> sources) {
    final items = <pw.Widget>[];
    for (final source in sources) {
      items.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            '- ${source.finalUrl}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
          ),
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        pw.Text(
          'No hay URLs de origen registradas.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  pw.Widget _limitations() {
    const bulletStyle = pw.TextStyle(
      fontSize: 9,
      color: PdfColors.grey800,
      height: 1.6,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '- Este informe se basa exclusivamente en información públicamente disponible y fuentes autorizadas.',
          style: bulletStyle,
        ),
        pw.Text(
          '- No se accedió a perfiles privados ni se evadió autenticación o controles de acceso.',
          style: bulletStyle,
        ),
        pw.Text(
          '- Los datos provenientes de fuentes están identificados y cada dato importante conserva su fuente.',
          style: bulletStyle,
        ),
        pw.Text(
          '- El nivel de confianza indica la fiabilidad atribuida a la fuente de cada dato.',
          style: bulletStyle,
        ),
        pw.Text(
          '- La información no verificada debe considerarse provisional y sujeta a confirmación.',
          style: bulletStyle,
        ),
      ],
    );
  }
}
