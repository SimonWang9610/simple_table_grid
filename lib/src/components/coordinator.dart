import 'package:flutter/foundation.dart';
import 'package:simple_table_grid/src/models/key.dart';

base mixin TableCoordinator {
  void notifyRebuild();

  // /// sync reorder operation without [notifyRebuild]
  // void afterReorder({
  //   required int from,
  //   required int to,
  //   required bool forColumn,
  // });

  // /// sync reindex operation without [notifyRebuild]
  // void afterReindex({
  //   Map<int, int>? newRowIndices,
  //   Map<int, int>? newColumnIndices,
  // });

  bool isColumnHeader(int vicinityRow);

  List<ColumnKey> get orderedColumns;
}

base mixin TableCoordinatorMixin {
  TableCoordinator? _coordinator;

  @protected
  TableCoordinator get coordinator {
    assert(
      _coordinator != null,
      "TableCoordinator is not set. Please set it before using.",
    );
    return _coordinator!;
  }

  void bindCoordinator(TableCoordinator coordinator) {
    _coordinator = coordinator;
  }

  @mustCallSuper
  void dispose() {
    _coordinator = null;
  }
}
