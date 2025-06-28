import 'dart:io';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:path_provider/path_provider.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

extension DataExporterFromConfigExt on ExporterConfig {
  DataExporter get _exporter => DataExporter(this);

  Future<void> save({
    required HeaderDataConverter headerConverter,
    required CellDataConverter cellConverter,
    required List<HeaderData> headers,
    required List<RowData> rows,
  }) {
    return _exporter.save(
      headerConverter: headerConverter,
      cellConverter: cellConverter,
      headers: headers,
      rows: rows,
    );
  }
}

sealed class DataExporter {
  const DataExporter._();

  factory DataExporter(ExporterConfig config) {
    if (config is ExcelExporterConfig) {
      return _ExcelExporter(config);
    } else if (config is PdfExporterConfig) {
      return _PdfExporter(config);
    } else {
      throw ArgumentError(
          "Unsupported exporter config type: ${config.runtimeType}");
    }
  }

  Future<void> save({
    required HeaderDataConverter headerConverter,
    required CellDataConverter cellConverter,
    required List<HeaderData> headers,
    required List<RowData> rows,
  });
}

final class _ExcelExporter extends DataExporter {
  final ExcelExporterConfig config;

  const _ExcelExporter(this.config) : super._();

  @override
  Future<void> save({
    required HeaderDataConverter headerConverter,
    required CellDataConverter cellConverter,
    required List<HeaderData> headers,
    required List<RowData> rows,
  }) async {
    final xlxs = Excel.createExcel();
    final sheet = xlxs[config.sheetName];

    final headerRow = headers
        .map(
          (e) => TextCellValue(headerConverter(e)),
        )
        .toList();

    final dataRows = rows
        .map(
          (row) => headers
              .map(
                (col) => TextCellValue(cellConverter(row, col.key)),
              )
              .toList(),
        )
        .toList();

    sheet.appendRow(headerRow);

    for (final dataRow in dataRows) {
      sheet.appendRow(dataRow);
    }

    print("sheet rows: ${sheet.rows.length}");

    try {
      final bytes = xlxs.save();

      if (bytes == null) {
        throw Exception("Failed to save Excel file.");
      }

      return _saveFile(bytes, config.filenameWithExtension);
    } catch (e) {
      rethrow;
    }
  }
}

final class _PdfExporter extends DataExporter {
  final PdfExporterConfig config;
  const _PdfExporter(this.config) : super._();

  @override
  Future<void> save({
    required HeaderDataConverter headerConverter,
    required CellDataConverter cellConverter,
    required List<HeaderData> headers,
    required List<RowData> rows,
  }) async {
    final pdf = pw.Document();

    final padding = pw.EdgeInsets.symmetric(
      horizontal: 8.0,
      vertical: 4.0,
    );

    final headerWidgets = headers
        .map(
          (e) => pw.Padding(
            padding: padding,
            child: pw.Text(
              headerConverter(e),
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: config.headerFontSize,
              ),
            ),
          ),
        )
        .toList();

    final dataRows = rows
        .map(
          (row) => headers
              .map(
                (col) => pw.Padding(
                  padding: padding,
                  child: pw.Text(
                    cellConverter(row, col.key),
                    style: pw.TextStyle(
                      fontSize: config.cellFontSize,
                    ),
                  ),
                ),
              )
              .toList(),
        )
        .toList();

    pw.Widget buildHeader(pw.Context context) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (config.title != null)
            pw.Text(
              config.title!,
              style: pw.TextStyle(
                fontSize: config.titleFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          if (config.logo != null)
            pw.Image(
              pw.MemoryImage(config.logo!),
              width: config.logoWidth,
              height: config.logoHeight,
            ),
        ],
      );
    }

    final page = pw.MultiPage(
      pageFormat: PdfPageFormat.standard,
      maxPages: config.maxPage,
      header: config.title != null || config.logo != null ? buildHeader : null,
      build: (pw.Context context) {
        return [
          pw.Table(
            border: pw.TableBorder.all(width: 0.3),
            tableWidth: pw.TableWidth.min,
            children: [
              // Header Row
              pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: headerWidgets,
              ),
              // Data Rows
              ...dataRows.map(
                (row) => pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: row,
                ),
              ),
            ],
          ),
        ];
      },
    );

    pdf.addPage(page);

    try {
      final bytes = await pdf.save();

      if (bytes.isEmpty) {
        throw Exception("Failed to save PDF file.");
      }

      return _saveFile(bytes, config.filenameWithExtension);
    } catch (e) {
      rethrow;
    }
  }
}

Future<void> _saveFile(List<int> bytes, String filename) async {
  String? path;

  if (Platform.isAndroid) {
    final Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      path = directory.path;
    }
  } else if (Platform.isIOS || Platform.isLinux || Platform.isWindows) {
    final Directory? directory = await getDownloadsDirectory();
    path = directory?.path;
  } else if (Platform.isMacOS) {
    Directory? directory = await getDownloadsDirectory();
    path = directory?.path;
  } else {
    throw UnsupportedError(
      "Unsupported platform for saving files: ${Platform.operatingSystem}",
    );
  }

  if (path == null) {
    throw Exception("Failed to get a valid path for saving files.");
  }

  final File file =
      File(Platform.isWindows ? '$path\\$filename' : '$path/$filename');

  await file.writeAsBytes(bytes, flush: true);
}
