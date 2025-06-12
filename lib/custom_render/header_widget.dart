import 'package:flutter/material.dart';
import 'package:simple_table_grid/custom_render/auto_cursor_region.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

typedef HeaderResizeCallback = void Function(
  ColumnKey columnKey,
  ResizeDirection direction,
  double delta,
  bool isEnd,
);

class HeaderWidget extends StatefulWidget {
  final Border? border;
  final EdgeInsets? padding;
  final ColumnHeaderDetail detail;
  final TableCellDetailBuilder<ColumnHeaderDetail> builder;
  final HeaderResizeCallback? onResize;
  final bool isMiddleHeader;

  const HeaderWidget({
    super.key,
    this.border,
    this.padding,
    required this.detail,
    required this.builder,
    this.onResize,
    this.isMiddleHeader = true,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  MouseCursor _cursor = SystemMouseCursors.basic;
  ResizeDirection? _resizeDirection;

  @override
  Widget build(BuildContext context) {
    Widget child = widget.builder(context, widget.detail);

    if (widget.padding != null) {
      child = Padding(
        padding: widget.padding!,
        child: child,
      );
    }

    if (widget.border != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          border: widget.border,
        ),
        child: child,
      );
    }

    return AutoCursorWidget(
      onHover: widget.onResize != null ? _getCursor : null,
      onMove: widget.onResize != null ? _onMove : null,
      child: child,
    );
  }

  MouseCursor _getCursor(Offset? offset) {
    if (offset == null) {
      print('Pointer exit, resetting cursor');
      _cursor = SystemMouseCursors.basic;
      _resizeDirection = null;
      return _cursor;
    }

    if (offset.dx > 0.1 && offset.dx < 0.9) {
      _cursor = SystemMouseCursors.basic;
      _resizeDirection = null;
    } else if (widget.isMiddleHeader) {
      _resizeDirection =
          offset.dx <= 0.1 ? ResizeDirection.left : ResizeDirection.right;
      _cursor = SystemMouseCursors.resizeColumn;
    } else {
      _cursor = SystemMouseCursors.basic;
    }

    return _cursor;
  }

  void _onMove(Offset delta, bool isEnd) {
    if (_resizeDirection == null || isEnd) {
      _resizeDirection = null;
      return;
    }

    widget.onResize?.call(
      widget.detail.columnKey,
      _resizeDirection!,
      delta.dx,
      isEnd,
    );
  }
}
