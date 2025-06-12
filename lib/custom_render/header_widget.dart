import 'package:flutter/material.dart';
import 'package:simple_table_grid/custom_render/auto_cursor_region.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class HeaderWidget extends StatefulWidget {
  final Border? border;
  final EdgeInsets? padding;
  final ColumnHeaderDetail detail;
  final TableCellDetailBuilder<ColumnHeaderDetail> builder;
  final bool isMiddleHeader;

  const HeaderWidget({
    super.key,
    this.border,
    this.padding,
    required this.detail,
    required this.builder,
    this.isMiddleHeader = true,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  MouseCursor _cursor = SystemMouseCursors.basic;

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
      onPointerCallback: _getCursor,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (_cursor != SystemMouseCursors.resizeColumn) return;
        },
        child: child,
      ),
    );
  }

  MouseCursor _getCursor(Offset? offset) {
    if (offset == null) {
      _cursor = SystemMouseCursors.basic;
      return _cursor;
    }

    if (offset.dx > 0.1 && offset.dx < 0.9) {
      _cursor = SystemMouseCursors.basic;
    } else if (widget.isMiddleHeader) {
      _cursor = SystemMouseCursors.resizeColumn;
    } else {
      _cursor = SystemMouseCursors.basic;
    }

    return _cursor;
  }
}
