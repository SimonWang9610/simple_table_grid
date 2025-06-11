import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/components/column_manager.dart';
import 'package:simple_table_grid/src/controller.dart';
import 'package:simple_table_grid/src/models/key.dart';

base mixin TableColumnImplMixin on TableController {
  @protected
  TableColumnManager get columnManager;

  @override
  void addColumn(ColumnKey column, {bool pinned = false}) {
    columnManager.add(column, pinned: pinned);
  }

  @override
  void removeColumn(ColumnKey key) {
    columnManager.remove(key);
  }

  @override
  void pinColumn(ColumnKey key) {
    columnManager.pin(key);
  }

  @override
  void unpinColumn(ColumnKey key) {
    columnManager.unpin(key);
  }

  @override
  void reorderColumn(ColumnKey from, ColumnKey to) {
    columnManager.reorder(from, to);
  }

  @override
  int get columnCount => columnManager.columnCount;

  @override
  int get pinnedColumnCount => columnManager.pinnedColumnCount;

  @override
  List<ColumnKey> get orderedColumns => columnManager.orderedColumns;

  @override
  ColumnKey getColumnKey(int index) {
    if (index < 0 || index >= columnManager.columnCount) {
      throw RangeError.index(index, columnManager.orderedColumns, 'index');
    }
    return columnManager.orderedColumns[index];
  }
}
