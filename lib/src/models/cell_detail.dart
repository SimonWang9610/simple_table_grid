import 'package:simple_table_grid/src/models/cell_index.dart';

typedef ColumnId = String;

sealed class CellDetail {
  final ColumnId columnId;
  final bool isPinned;
  final bool selected;
  final bool hovering;

  const CellDetail({
    required this.columnId,
    this.isPinned = false,
    this.selected = false,
    this.hovering = false,
  });

  @override
  bool operator ==(covariant CellDetail other) {
    if (identical(this, other)) return true;

    return other.columnId == columnId &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering;
  }

  @override
  int get hashCode {
    return columnId.hashCode ^
        isPinned.hashCode ^
        selected.hashCode ^
        hovering.hashCode;
  }

  @override
  String toString() {
    return 'CellDetail(columnId: $columnId, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}

final class ColumnHeaderDetail extends CellDetail {
  final int column;
  const ColumnHeaderDetail({
    required super.columnId,
    required this.column,
    super.isPinned = false,
    super.selected = false,
    super.hovering = false,
  });

  @override
  bool operator ==(covariant ColumnHeaderDetail other) {
    if (identical(this, other)) return true;

    return other.column == column &&
        other.columnId == columnId &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering;
  }

  @override
  int get hashCode =>
      column.hashCode ^
      columnId.hashCode ^
      isPinned.hashCode ^
      selected.hashCode ^
      hovering.hashCode;

  @override
  String toString() {
    return 'ColumnHeaderDetail(columnId: $columnId, column: $column, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}

final class TableCellDetail<T> extends CellDetail {
  final CellIndex index;
  final T? cellData;

  const TableCellDetail({
    required super.columnId,
    required this.index,
    this.cellData,
    super.isPinned = false,
    super.selected = false,
    super.hovering = false,
  });

  @override
  bool operator ==(covariant TableCellDetail other) {
    if (identical(this, other)) return true;

    return other.index == index &&
        other.columnId == columnId &&
        other.isPinned == isPinned &&
        other.selected == selected &&
        other.hovering == hovering &&
        other.cellData == cellData;
  }

  @override
  int get hashCode {
    return index.hashCode ^
        columnId.hashCode ^
        isPinned.hashCode ^
        selected.hashCode ^
        hovering.hashCode ^
        cellData.hashCode;
  }

  @override
  String toString() {
    return 'TableCellDetail(columnId: $columnId, index: $index, cellData: $cellData, isPinned: $isPinned, selected: $selected, hovering: $hovering)';
  }
}
