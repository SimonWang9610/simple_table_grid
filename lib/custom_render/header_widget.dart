import 'package:flutter/material.dart';
import 'package:simple_table_grid/custom_render/auto_cursor_region.dart';
import 'package:simple_table_grid/custom_render/drag_widget.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';

class HeaderWidget extends StatefulWidget {
  final Border? border;
  final EdgeInsets? padding;
  final ColumnHeaderDetail detail;
  final TableCellDetailBuilder<ColumnHeaderDetail> builder;
  final TableSizer? sizer;
  final bool isMiddleHeader;
  final bool enableDrag;

  const HeaderWidget({
    super.key,
    this.border,
    this.padding,
    required this.detail,
    required this.builder,
    this.sizer,
    this.isMiddleHeader = true,
    this.enableDrag = true,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  late final ValueNotifier<bool> _canDrag =
      ValueNotifier<bool>(widget.enableDrag);

  TableCursorDelegate? get cursorDelegate =>
      widget.sizer as TableCursorDelegate?;

  @override
  void dispose() {
    _canDrag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.builder(context, widget.detail);

    if (widget.enableDrag && cursorDelegate != null) {
      child = ValueListenableBuilder(
        valueListenable: _canDrag,
        builder: (_, canDrag, child) {
          return IgnorePointer(
            ignoring: !canDrag,
            child: child,
          );
        },
        child: DraggableCellWidget(
          detail: widget.detail,
          onAccept: (from, to) {},
          onDragStarted: () => cursorDelegate?.setDragging(true),
          onDragEnd: () => cursorDelegate?.setDragging(false),
          child: child,
        ),
      );
    }

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
      onHover: (offset) {
        final cursor = cursorDelegate?.getCursor(
              offset: offset,
              direction: Axis.horizontal,
            ) ??
            SystemMouseCursors.basic;

        if (widget.enableDrag) {
          _canDrag.value = cursor != SystemMouseCursors.resizeColumn &&
              cursor != SystemMouseCursors.resizeRow;
        }

        return cursor;
      },
      onMove: (delta, status) {
        cursorDelegate?.onCursorMove(
          widget.detail.columnKey,
          delta.dx,
          status,
        );
      },
      child: child,
    );
  }
}
