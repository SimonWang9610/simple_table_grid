import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

base mixin TableDataSourceImplMixin on TableController {
  @protected
  TableDataSource get dataSource;

  @override
  void addRows(
    List<RowData> rows, {
    bool skipDuplicates = false,
    bool removePlaceholder = true,
  }) {
    dataSource.add(rows);
  }

  @override
  void removeRows(List<RowKey> rows) {
    dataSource.removeByKeys(rows);
  }

  @override
  void reorderRow(RowKey from, RowKey to) {
    dataSource.reorderByKey(from, to);
  }

  @override
  void pinRow(RowKey key) {
    dataSource.pinByKey(key);
  }

  @override
  void unpinRow(RowKey key) {
    dataSource.unpinByKey(key);
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

  @override
  RowKey getRowKey(int index) {
    return dataSource.getRowKey(index);
  }

  @override
  RowKey? previousRow(RowKey key) {
    return dataSource.previousRow(key);
  }

  @override
  RowKey? nextRow(RowKey key) {
    return dataSource.nextRow(key);
  }
}
