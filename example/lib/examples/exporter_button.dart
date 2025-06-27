import 'package:example/exporter.dart';
import 'package:example/models/custom_data_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class ExcelExportButton extends StatelessWidget {
  final TableController controller;
  const ExcelExportButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final exporter = ExcelExporter(controller);

        await exporter.exportToExcel(
          "exported_example",
          skippedColumns: [ColumnKey("Menu")],
          headerConverter: (headerData) {
            final data = (headerData.data as CustomDataGridModel);
            return data.displayName ?? data.columnName;
          },
          cellConverter: (rowData, column) {
            return rowData[column]?.toString() ?? "-";
          },
        );
      },
      icon: const Icon(Icons.file_download),
      label: Text(
        "Export to Excel",
      ),
    );
  }
}

class PdfExportButton extends StatelessWidget {
  final TableController controller;
  const PdfExportButton({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final exporter = PdfExporter(controller);

        await exporter.exportToPdf(
          "exported_example",
          skippedColumns: [ColumnKey("Menu")],
          headerConverter: (headerData) {
            final data = (headerData.data as CustomDataGridModel);
            return data.displayName ?? data.columnName;
          },
          cellConverter: (rowData, column) {
            return rowData[column]?.toString() ?? "-";
          },
        );
      },
      icon: const Icon(Icons.picture_as_pdf),
      label: Text(
        "Export to PDF",
      ),
    );
  }
}
