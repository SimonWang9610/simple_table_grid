import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/models/cell_detail.dart';

typedef TableCellDetailBuilder<T extends CellDetail> = Widget Function(
  BuildContext context,
  T detail,
);

enum ResizeDirection {
  left,
  right,
  up,
  down,
}

enum FocusStrategy {
  row,
  column,
  cell,
}
