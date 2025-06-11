import 'package:simple_table_grid/src/models/cell_index.dart';
import 'package:simple_table_grid/src/models/key.dart';

sealed class CellDetail {
  final ColumnKey columnKey;
  final bool isPinned;
  final bool selected;
  final bool hovering;

  const CellDetail({
    required this.columnKey,
    this.isPinned = false,
    this.selected = false,
    this.hovering = false,
  });

  @override
  bool operator ==(covariant CellDetail other) {
    if (identical(this, other)) return true;

    return other.columnKey == columnKey &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering;
  }

  @override
  int get hashCode {
    return columnKey.hashCode ^
        isPinned.hashCode ^
        selected.hashCode ^
        hovering.hashCode;
  }

  @override
  String toString() {
    return 'CellDetail(columnKey: $columnKey, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}

final class ColumnHeaderDetail extends CellDetail {
  final int column;
  const ColumnHeaderDetail({
    required super.columnKey,
    required this.column,
    super.isPinned = false,
    super.selected = false,
    super.hovering = false,
  });

  @override
  bool operator ==(covariant ColumnHeaderDetail other) {
    if (identical(this, other)) return true;

    return other.column == column &&
        other.columnKey == columnKey &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering;
  }

  @override
  int get hashCode =>
      column.hashCode ^
      columnKey.hashCode ^
      isPinned.hashCode ^
      selected.hashCode ^
      hovering.hashCode;

  @override
  String toString() {
    return 'ColumnHeaderDetail(columnKey: $columnKey, column: $column, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}

final class TableCellDetail<T> extends CellDetail {
  final RowKey rowKey;
  final CellIndex index;
  final T? cellData;

  const TableCellDetail({
    required super.columnKey,
    required this.index,
    required this.rowKey,
    this.cellData,
    super.isPinned = false,
    super.selected = false,
    super.hovering = false,
  });

  CellKey get cellKey => CellKey(rowKey, columnKey);

  @override
  bool operator ==(covariant TableCellDetail other) {
    if (identical(this, other)) return true;

    return other.index == index &&
        other.columnKey == columnKey &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering &&
        other.cellData == cellData;
  }

  @override
  int get hashCode {
    return index.hashCode ^
        columnKey.hashCode ^
        isPinned.hashCode ^
        selected.hashCode ^
        hovering.hashCode ^
        cellData.hashCode;
  }

  @override
  String toString() {
    return 'TableCellDetail(columnKey: $columnKey, index: $index, cellData: $cellData, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}
