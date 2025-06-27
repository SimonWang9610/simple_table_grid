import 'package:example/helper.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

typedef HeaderDataConverter = String Function(HeaderData headerData);
typedef CellDataConverter = String Function(RowData rowData, ColumnKey column);

class ExcelExporter {
  final TableController controller;

  ExcelExporter(this.controller);

  Future<void> exportToExcel(
    String filename, {
    String sheetName = "Sheet1",
    DataExportOption option = DataExportOption.all,
    List<ColumnKey> skippedColumns = const [],
    required HeaderDataConverter headerConverter,
    required CellDataConverter cellConverter,
  }) async {
    final xlxs = Excel.createExcel();
    final sheet = xlxs[sheetName];

    final columns = controller.columns.exportColumns(skippedColumns);
    final rows = controller.rows.exportRows(option);

    final headerRow =
        columns.map((e) => TextCellValue(headerConverter(e))).toList();
    final dataRows = rows
        .map(
          (row) => columns
              .map((col) => TextCellValue(cellConverter(row, col.key)))
              .toList(),
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

      await ExampleHelper.saveFile(bytes, "$filename.xlsx");
    } catch (e) {
      rethrow;
    }
  }
}

class PdfExporter {
  final TableController controller;

  PdfExporter(this.controller);

  Future<void> exportToPdf(
    String filename, {
    DataExportOption option = DataExportOption.all,
    List<ColumnKey> skippedColumns = const [],
    required HeaderDataConverter headerConverter,
    required CellDataConverter cellConverter,
  }) async {
    final columns = controller.columns.exportColumns(skippedColumns);
    final rows = controller.rows.exportRows(option);

    final doc = pw.Document();

    final page = pw.MultiPage(
      pageFormat: PdfPageFormat.standard,
      build: (pw.Context context) {
        return [
          pw.Table(
            border: pw.TableBorder.all(width: 0.3),
            tableWidth: pw.TableWidth.min,
            children: [
              // Header Row
              pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: columns
                    .map(
                      (col) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: pw.Text(
                          headerConverter(col),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              // Data Rows
              ...rows.map(
                (row) => pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: columns
                      .map((col) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: pw.Text(
                              cellConverter(row, col.key),
                              style: pw.TextStyle(
                                fontSize: 8,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ];
      },
    );

    doc.addPage(page);

    try {
      final bytes = await doc.save();

      await ExampleHelper.saveFile(bytes, "$filename.pdf");
    } catch (e) {
      rethrow;
    }
  }
}
