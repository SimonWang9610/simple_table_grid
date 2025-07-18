import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

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

enum PointerStatus { up, down, move }

class ResizeTarget<T extends TableKey> {
  final T key;
  final ResizeDirection direction;

  const ResizeTarget({
    required this.key,
    required this.direction,
  });

  @override
  String toString() {
    return 'ResizeTarget(key: $key, direction: $direction)';
  }
}

class ReorderPredicate<T extends TableKey> {
  final T candidate;
  final bool afterCandidate;

  const ReorderPredicate({
    required this.candidate,
    this.afterCandidate = true,
  });

  bool isReorderTarget(CellDetail detail) {
    return switch (detail) {
      TableHeaderDetail(columnKey: final key) => key == candidate,
      TableCellDetail(columnKey: final key) => key == candidate,
    };
  }
}
