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

final class TableHeaderDetail extends CellDetail {
  const TableHeaderDetail({
    required super.columnKey,
    super.isPinned = false,
    super.selected = false,
    super.hovering = false,
  });

  @override
  bool operator ==(covariant TableHeaderDetail other) {
    if (identical(this, other)) return true;

    return other.columnKey == columnKey &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering;
  }

  @override
  int get hashCode =>
      columnKey.hashCode ^
      isPinned.hashCode ^
      selected.hashCode ^
      hovering.hashCode;

  @override
  String toString() {
    return 'TableHeaderDetail(columnKey: $columnKey, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}

final class TableCellDetail<T> extends CellDetail {
  final RowKey rowKey;
  final T? cellData;

  const TableCellDetail({
    required super.columnKey,
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

    return other.rowKey == rowKey &&
        other.columnKey == columnKey &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering &&
        other.cellData == cellData;
  }

  @override
  int get hashCode {
    return rowKey.hashCode ^
        columnKey.hashCode ^
        isPinned.hashCode ^
        selected.hashCode ^
        hovering.hashCode ^
        cellData.hashCode;
  }

  @override
  String toString() {
    return 'TableCellDetail(columnKey: $columnKey, rowKey: $rowKey, cellData: $cellData, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}
