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
  final T from;
  final T to;
  final bool fromPinned;
  final bool toPinned;
  final bool afterTo;

  const ReorderPredicate({
    required this.from,
    required this.to,
    required this.fromPinned,
    required this.toPinned,
    required this.afterTo,
  });

  bool isReorderTarget(CellDetail detail) {
    return switch (detail) {
      TableHeaderDetail(columnKey: final key) => key == to,
      TableCellDetail(columnKey: final key) => key == to,
    };
  }

  @override
  String toString() {
    return 'ReorderPredicate(from: $from, to: $to, fromPinned: $fromPinned, toPinned: $toPinned, afterTo: $afterTo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReorderPredicate &&
        other.from == from &&
        other.to == to &&
        other.fromPinned == fromPinned &&
        other.toPinned == toPinned &&
        other.afterTo == afterTo;
  }

  @override
  int get hashCode {
    return from.hashCode ^
        to.hashCode ^
        fromPinned.hashCode ^
        toPinned.hashCode ^
        afterTo.hashCode;
  }
}
