import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controller.dart';
import 'package:simple_table_grid/src/data_source.dart';

base mixin TableDataSourceImplMixin on TableController {
  @protected
  TableDataSource get dataSource;

  @override
  void addRows(
    List<TableRowData> rows, {
    bool skipDuplicates = false,
    bool removePlaceholder = true,
  }) {
    dataSource.add(
      rows,
      skipDuplicates: skipDuplicates,
    );
  }

  @override
  void removeRows(
    List<int> rows, {
    bool showPlaceholder = false,
  }) {
    dataSource.remove(
      rows
          .map(
            (r) => toVicinityRow(r),
          )
          .toList(),
    );
  }

  @override
  void reorderRow(int fromDataIndex, int toDataIndex) {
    dataSource.reorder(
      toVicinityRow(fromDataIndex),
      toVicinityRow(toDataIndex),
    );
  }

  @override
  void pinRow(int dataIndex) {
    dataSource.pin(
      toVicinityRow(dataIndex),
    );
  }

  @override
  void unpinRow(int dataIndex) {
    dataSource.unpin(
      toVicinityRow(dataIndex),
    );
  }

  @override
  void toggleHeaderVisibility(bool alwaysShowHeader) {
    dataSource.alwaysShowHeader = alwaysShowHeader;
  }

  @override
  int get rowCount => dataSource.rowCount;

  @override
  int get pinnedRowCount => dataSource.pinnedRowCount;

  @override
  int get dataCount => dataSource.dataCount;
}
