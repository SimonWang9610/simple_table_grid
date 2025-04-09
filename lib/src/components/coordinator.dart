import 'package:flutter/foundation.dart';

base mixin TableCoordinator {
  void notifyRebuild();

  void adaptReordering({
    required int from,
    required int to,
    required bool forColumn,
  });

  void adaptRemoval({
    Map<int, int>? newRowIndices,
    Map<int, int>? newColumnIndices,
  });

  bool isColumnHeader(int vicinityRow);
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
