import 'package:flutter/foundation.dart';

base mixin TableCoordinator {
  void notifyRebuild();
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
