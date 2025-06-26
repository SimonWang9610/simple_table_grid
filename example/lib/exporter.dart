import 'dart:io';

import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

typedef HeaderCellConverter = CellValue Function(HeaderData headerData);
typedef RowCellConverter = CellValue Function(
    RowData rowData, HeaderData headerData);

class ExcelExporter {
  final TableController controller;

  ExcelExporter(this.controller);

  Future<void> exportToExcel(
    String filePath, {
    String sheetName = "Sheet1",
    DataExportOption option = DataExportOption.all,
    List<ColumnKey> skippedColumns = const [],
    required HeaderCellConverter headerConverter,
    required RowCellConverter cellConverter,
  }) async {
    final xlxs = Excel.createExcel();
    final sheet = xlxs[sheetName];

    final columns = controller.columns.exportColumns(skippedColumns);
    final rows = controller.rows.exportRows(option);

    final headerRow = columns.map(headerConverter).toList();
    final dataRows = rows
        .map(
          (row) => columns.map((col) => cellConverter(row, col)).toList(),
        )
        .toList();

    sheet.appendRow(headerRow);
    for (final dataRow in dataRows) {
      sheet.appendRow(dataRow);
    }

    try {
      final bytes = xlxs.save();

      if (bytes == null) {
        throw Exception("Failed to save Excel file.");
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } catch (e) {
      rethrow;
    }
  }
}

typedef HeaderWidgetConverter = pw.Widget Function(
    pw.Context context, HeaderData headerData);

typedef CellWidgetConverter = pw.Widget Function(
    pw.Context context, RowData rowData, HeaderData headerData);

class PdfExporter {
  final TableController controller;

  PdfExporter(this.controller);

  Future<void> exportToPdf(
    String filePath, {
    DataExportOption option = DataExportOption.all,
    List<ColumnKey> skippedColumns = const [],
    required HeaderWidgetConverter headerConverter,
    required CellWidgetConverter cellConverter,
  }) async {
    final columns = controller.columns.exportColumns(skippedColumns);
    final rows = controller.rows.exportRows(option);

    final doc = pw.Document();

    final page = pw.Page(
      pageFormat: PdfPageFormat.standard,
      build: (pw.Context context) {
        return pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header Row
            pw.TableRow(
              children:
                  columns.map((col) => headerConverter(context, col)).toList(),
            ),
            // Data Rows
            ...rows.map(
              (row) => pw.TableRow(
                children: columns
                    .map((col) => cellConverter(context, row, col))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );

    doc.addPage(page);

    try {
      final file = File(filePath);
      await file.writeAsBytes(await doc.save());
    } catch (e) {
      rethrow;
    }
  }
}
