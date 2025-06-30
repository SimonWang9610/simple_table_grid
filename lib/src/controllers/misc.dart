import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

base mixin TableCursorDelegate on TableSizer {
  MouseCursor _cursor = SystemMouseCursors.basic;
  bool _dragging = false;

  void setDragging(bool dragging) {
    _dragging = dragging;
  }

  ResizeDirection? _resizeDirection;

  MouseCursor getCursor({
    double threshold = 0.05,
    Offset? offset,
    required Axis direction,
  }) {
    assert(
      threshold >= 0 && threshold <= 1,
      'Threshold must be between 0 and 1',
    );

    if (_dragging) {
      _cursor = SystemMouseCursors.basic;
      return _cursor;
    }

    final mainExtent = direction == Axis.horizontal ? offset?.dx : offset?.dy;
    if (mainExtent == null) {
      _cursor = SystemMouseCursors.basic;
      return _cursor;
    }

    assert(
      mainExtent >= 0 && mainExtent <= 1,
      'Offset must be between 0 and 1',
    );

    if (mainExtent <= threshold || mainExtent >= 1 - threshold) {
      _resizeDirection =
          switch ((mainExtent <= threshold, direction == Axis.horizontal)) {
        (true, true) => ResizeDirection.left,
        (false, true) => ResizeDirection.right,
        (true, false) => ResizeDirection.up,
        (false, false) => ResizeDirection.down,
      };

      _cursor = direction == Axis.horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow;
    } else {
      _cursor = SystemMouseCursors.basic;
    }

    return _cursor;
  }

  void onCursorMove<T extends TableKey>(
    T key,
    double delta,
    PointerStatus status,
  ) {
    if (_dragging) return;

    if (status == PointerStatus.up) {
      setResizeTarget(null);
      _resizeDirection = null;
      return;
    }

    if (status == PointerStatus.down && _resizeDirection != null) {
      setResizeTarget(
        ResizeTarget(
          key: key,
          direction: _resizeDirection!,
        ),
      );
    } else {
      resize(delta);
    }
  }

  @override
  void dispose() {
    _cursor = SystemMouseCursors.basic;
    _resizeDirection = null;
    _dragging = false;
    super.dispose();
  }
}
