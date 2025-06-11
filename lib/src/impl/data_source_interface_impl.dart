import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/models/key.dart';

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
    dataSource.reorder(fromDataIndex, toDataIndex);
  }

  @override
  void pinRow(int dataIndex) {
    dataSource.pin(dataIndex);
  }

  @override
  void unpinRow(int dataIndex) {
    dataSource.unpin(dataIndex);
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
  int toVicinityRow(int row) {
    assert(
      row >= 0 && row < dataCount,
      "Data index $row is out of bounds for rows of length $dataCount",
    );
    return dataSource.toVicinityRow(row);
  }

  @override
  CellIndex getCellIndex(ChildVicinity vicinity) {
    final row = dataSource.toCellRow(vicinity.row);

    assert(
      row >= 0 && row < dataCount,
      "Row index $row must be greater than or equal to 0",
    );

    assert(
      vicinity.column >= 0 && vicinity.column < columnCount,
      "Column index ${vicinity.column} must be greater than or equal to 0",
    );

    return CellIndex(row, vicinity.column);
  }
}
