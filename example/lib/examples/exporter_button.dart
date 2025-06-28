import 'package:example/models/custom_data_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        final config = ExcelExporterConfig(
          filename: "exported_example",
          sheetName: "Example Data",
        );

        await controller.saveDataToFile(
          config,
          option: ExporterOption.all,
          ignoredColumns: [ColumnKey("Menu")],
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
        final logo = await rootBundle.load('assets/acre-logo-dark.png');

        final config = PdfExporterConfig(
          filename: "exported_example",
          title: "Exported Example",
          logo: logo.buffer.asUint8List(),
        );

        await controller.saveDataToFile(
          config,
          option: ExporterOption.current,
          ignoredColumns: [ColumnKey("Menu")],
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
