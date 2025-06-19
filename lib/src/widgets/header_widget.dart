import 'package:flutter/material.dart';
import 'package:simple_table_grid/src/widgets/auto_cursor_region.dart';
import 'package:simple_table_grid/src/widgets/drag_widget.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';

typedef TableCellReorderCallback<T extends CellDetail> = void Function(
  T from,
  T to,
);

class HeaderWidget extends StatefulWidget {
  final Border? border;
  final EdgeInsets? padding;
  final ColumnHeaderDetail detail;
  final TableCellDetailBuilder<ColumnHeaderDetail> builder;
  final TableSizer? sizer;
  final TableCellReorderCallback<ColumnHeaderDetail>? onReorder;

  const HeaderWidget({
    super.key,
    this.border,
    this.padding,
    required this.detail,
    required this.builder,
    this.sizer,
    this.onReorder,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  late final ValueNotifier<bool> _canDrag =
      ValueNotifier<bool>(widget.onReorder != null);

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

    if (widget.onReorder != null && cursorDelegate != null) {
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
          feedback: _buildFeedback(context, child),
          onAccept: widget.onReorder!,
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

        if (widget.onReorder != null) {
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

  Widget _buildFeedback(BuildContext context, Widget child) {
    final box = context.findRenderObject() as RenderBox?;

    if (box == null) return child;

    final size = box.size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
