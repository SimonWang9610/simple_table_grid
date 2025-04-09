import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/models/cell_detail.dart';

enum TableSelectionStrategy {
  none,
  row,
  column,
  cell,
}

enum TableHoveringStrategy {
  none,
  row,
  column,
}

typedef TableCellDetailBuilder<T extends CellDetail> = Widget Function(
  BuildContext context,
  T detail,
);

typedef TableCellDataExtractor<T> = dynamic Function(
  T rowData,
  ColumnId columnId,
);
