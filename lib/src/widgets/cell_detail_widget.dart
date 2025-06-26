import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';
import 'package:simple_table_grid/src/widgets/auto_cursor_region.dart';

typedef DragCellCallback<T extends CellDetail> = void Function(
  T from,
  T to,
);

class DraggableCellWidget<T extends CellDetail> extends StatelessWidget {
  final T detail;
  final Widget child;
  final Widget? feedback;
  final DragCellCallback<T> onAccept;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  const DraggableCellWidget({
    super.key,
    required this.detail,
    required this.onAccept,
    this.onDragStarted,
    this.onDragEnd,
    required this.child,
    this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final target = DragTarget<T>(
      onAcceptWithDetails: (from) => onAccept(from.data, detail),
      builder: (ctx, _, __) => child,
    );

    final draggable = Draggable<T>(
      data: detail,
      onDragStarted: onDragStarted,
      onDragEnd: onDragEnd != null ? (_) => onDragEnd?.call() : null,
      feedback: feedback ??
          Material(
            elevation: 6.0,
            child: child,
          ),
      childWhenDragging: const SizedBox.shrink(),
      child: target,
    );

    return draggable;
  }
}

const _defaultSize = Size(100, 50);

class CellDetailWidget<T extends CellDetail> extends StatefulWidget {
  final T detail;
  final TableCursorDelegate cursorDelegate;
  final TableCellDetailBuilder<T> builder;
  final DragCellCallback<T>? onReorder;
  final bool dragEnabled;
  final bool resizeEnabled;
  final bool isRightEdge;
  final bool isBottomEdge;

  const CellDetailWidget({
    super.key,
    required this.isRightEdge,
    required this.isBottomEdge,
    required this.dragEnabled,
    required this.resizeEnabled,
    required this.cursorDelegate,
    required this.detail,
    required this.builder,
    this.onReorder,
  });

  @override
  State<CellDetailWidget<T>> createState() => _CellDetailWidgetState<T>();
}

class _CellDetailWidgetState<T extends CellDetail>
    extends State<CellDetailWidget<T>> {
  late final ValueNotifier<bool> _canDrag =
      ValueNotifier<bool>(widget.dragEnabled && widget.onReorder != null);

  final _size = ValueNotifier<Size?>(null);

  @override
  void dispose() {
    _size.dispose();
    _canDrag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateCellSize();

    final gridTheme = TableGridTheme.of(context);

    final padding = gridTheme.border?.calculatePadding(
      widget.isRightEdge,
      widget.isBottomEdge,
    );

    final border = gridTheme.border?.calculateBorder(
      widget.isRightEdge,
      widget.isBottomEdge,
    );

    final cellTheme = switch (widget.detail) {
      TableHeaderDetail() => gridTheme.headerTheme,
      TableCellDetail() => gridTheme.cellTheme,
    };

    Widget child = widget.builder(context, widget.detail);

    if (widget.dragEnabled && widget.onReorder != null) {
      child = ValueListenableBuilder(
        valueListenable: _canDrag,
        builder: (_, canDrag, child) {
          return IgnorePointer(
            ignoring: !canDrag,
            child: child,
          );
        },
        child: DraggableCellWidget<T>(
          detail: widget.detail,
          feedback: _buildFeedback(child, cellTheme),
          onAccept: widget.onReorder!,
          onDragStarted: () => widget.cursorDelegate.setDragging(true),
          onDragEnd: () => widget.cursorDelegate.setDragging(false),
          child: child,
        ),
      );
    }

    if (padding != null) {
      child = Padding(
        padding: padding,
        child: child,
      );
    }

    child = DecoratedBox(
      decoration: BoxDecoration(
        border: border,
        color: widget.detail.selected
            ? cellTheme.selectedColor
            : widget.detail.hovering
                ? cellTheme.hoveringColor
                : cellTheme.unselectedColor,
      ),
      child: child,
    );

    if (!widget.resizeEnabled && !widget.dragEnabled) {
      return child;
    }

    return AutoCursorWidget(
      onHover: (offset) {
        final cursor = widget.cursorDelegate.getCursor(
          offset: offset,
          direction: widget.detail is TableHeaderDetail
              ? Axis.horizontal
              : Axis.vertical,
        );

        if (widget.dragEnabled) {
          _canDrag.value = cursor != SystemMouseCursors.resizeColumn &&
              cursor != SystemMouseCursors.resizeRow;
        }

        return cursor;
      },
      onMove: (delta, status) {
        final (key, increment) = switch (widget.detail) {
          TableHeaderDetail() => (widget.detail.columnKey, delta.dx),
          TableCellDetail() => (
              (widget.detail as TableCellDetail).rowKey,
              delta.dy
            ),
        };

        widget.cursorDelegate.onCursorMove(
          key,
          increment,
          status,
        );
      },
      child: child,
    );
  }

  Widget _buildFeedback(Widget child, CellTheme cellTheme) {
    return ValueListenableBuilder(
      valueListenable: _size,
      builder: (_, size, __) {
        return SizedBox.fromSize(
          size: size ?? _defaultSize,
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cellTheme.hoveringColor,
              ),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// sync the drag feedback size with the actual cell size
  void _updateCellSize() {
    if (!widget.dragEnabled) return;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          _size.value = box.size;
        }
      },
    );
  }
}
