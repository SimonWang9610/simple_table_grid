import 'package:flutter/foundation.dart';
import 'package:simple_table_grid/src/models/key.dart';

typedef HeaderDataConverter = String Function(HeaderData headerData);
typedef CellDataConverter = String Function(RowData rowData, ColumnKey column);

/// Options for exporting data from the table.
enum ExporterOption {
  /// Export all data rows in the table, no matter if they are selected or displayed.
  all,

  /// Export only the data rows currently displayed in the table.
  /// For example, only export the searched rows.
  ///
  /// NOTE: for paginated tables, this will export the rows in the current page.
  current,

  /// Export only the data rows that are currently selected.
  selected,
}

sealed class ExporterConfig {
  final String filename;

  const ExporterConfig({required this.filename});

  String get filenameWithExtension;
}

class ExcelExporterConfig extends ExporterConfig {
  final String sheetName;

  const ExcelExporterConfig({
    required super.filename,
    this.sheetName = "Sheet1",
  });

  @override
  String get filenameWithExtension => "$filename.xlsx";
}

class PdfExporterConfig extends ExporterConfig {
  final String? title;
  final Uint8List? logo;
  final int maxPage;
  final double logoWidth;
  final double logoHeight;
  final double titleFontSize;
  final double headerFontSize;
  final double cellFontSize;

  const PdfExporterConfig({
    required super.filename,
    this.logoWidth = 100,
    this.logoHeight = 100,
    this.titleFontSize = 14,
    this.headerFontSize = 12,
    this.cellFontSize = 10,
    this.maxPage = 20,
    this.title,
    this.logo,
  });

  @override
  String get filenameWithExtension => "$filename.pdf";
}
