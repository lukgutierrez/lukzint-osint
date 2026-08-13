import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/investigation.dart';
import '../../domain/usecases/generate_pdf.dart';
import '../controllers/investigation_controller.dart';

/// Pantalla con la vista previa del informe PDF de una investigación.
///
/// Genera el informe con el mismo flujo que la exportación y lo muestra
/// dentro de la app mediante [PdfPreview]. Permite exportar (compartir)
/// e imprimir manteniendo la opción actual de generación de PDF.
class PdfPreviewScreen extends StatefulWidget {
  final InvestigationController controller;
  final Investigation investigation;

  const PdfPreviewScreen({
    super.key,
    required this.controller,
    required this.investigation,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Future<ReportDocument?>? _reportFuture;
  ReportDocument? _report;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _reportFuture = widget.controller.generatePdfReport(widget.investigation);
      });
    });
  }

  Future<void> _export() async {
    final report = _report;
    if (report == null) return;
    try {
      await Printing.sharePdf(bytes: report.bytes, filename: report.fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar el PDF: $e')),
      );
    }
  }

  void _reload() {
    setState(() {
      _reportFuture =
          widget.controller.generatePdfReport(widget.investigation);
      _report = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista previa del informe'),
        actions: [
          IconButton(
            onPressed: _export,
            tooltip: 'Exportar PDF',
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<ReportDocument?>(
          future: _reportFuture,
          builder: (context, snapshot) {
            if (_reportFuture == null ||
                snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final report = snapshot.data;
            if (report == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No se pudo generar el informe.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.controller.error ?? 'Error desconocido',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            _report = report;
            return PdfPreview(
              build: (_) async => report.bytes,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              pdfFileName: report.fileName,
              pdfPreviewPageDecoration: const BoxDecoration(
                color: Colors.white,
              ),
              actionBarTheme: const PdfActionBarTheme(
                backgroundColor: AppColors.primary,
              ),
              scrollViewDecoration: const BoxDecoration(
                color: AppColors.surface,
              ),
            );
          },
        ),
      ),
    );
  }
}
