import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:simple_table_grid/src/components/reorder_interfaces.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';
import 'package:simple_table_grid/src/widgets/auto_cursor_region.dart';

class DraggableCellWidget<T extends TableKey> extends StatelessWidget {
  final T tableKey;
  final Widget child;
  final Widget? feedback;
  final TableKeyReorderMixin<T> reorderMixin;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  const DraggableCellWidget({
    super.key,
    required this.tableKey,
    required this.reorderMixin,
    this.onDragStarted,
    this.onDragEnd,
    required this.child,
    this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    final target = DragTarget<T>(
      onAcceptWithDetails: (from) {
        reorderMixin.confirmReordering(true);
      },
      onMove: (from) {
        reorderMixin.reordering(
          from.data,
          tableKey,
        );
      },
      onLeave: (data) {
        reorderMixin.confirmReordering(false);
      },
      builder: (ctx, _, __) => child,
    );

    final draggable = Draggable<T>(
      data: tableKey,
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

class CellDetailWidget<T extends CellDetail, K extends TableKey>
    extends StatefulWidget {
  final T detail;
  final TableCursorDelegate cursorDelegate;
  final TableCellDetailBuilder<T> builder;
  final TableKeyReorderMixin<K>? reorderMixin;
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
    this.reorderMixin,
  });

  @override
  State<CellDetailWidget<T, K>> createState() => _CellDetailWidgetState<T, K>();
}

class _CellDetailWidgetState<T extends CellDetail, K extends TableKey>
    extends State<CellDetailWidget<T, K>> {
  late final ValueNotifier<bool> _canDrag =
      ValueNotifier<bool>(widget.dragEnabled && widget.reorderMixin != null);

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

    final isReorderTarget =
        widget.reorderMixin?.reorderPredicate?.isReorderTarget(widget.detail) ??
            false;

    final padding = gridTheme.calculatePadding(
      widget.isRightEdge,
      widget.isBottomEdge,
      isReorderTarget,
    );

    final border = gridTheme.calculateBorder(
      widget.isRightEdge,
      widget.isBottomEdge,
      isReorderTarget,
    );

    final cellTheme = switch (widget.detail) {
      TableHeaderDetail() => gridTheme.headerTheme,
      TableCellDetail() => gridTheme.cellTheme,
    };

    Widget child = widget.builder(context, widget.detail);

    final tableKey = widget.detail is TableHeaderDetail
        ? (widget.detail as TableHeaderDetail).columnKey
        : (widget.detail as TableCellDetail).rowKey;

    if (widget.dragEnabled && widget.reorderMixin != null) {
      child = ValueListenableBuilder(
        valueListenable: _canDrag,
        builder: (_, canDrag, child) {
          return IgnorePointer(
            ignoring: !canDrag,
            child: child,
          );
        },
        child: DraggableCellWidget(
          tableKey: tableKey,
          reorderMixin: widget.reorderMixin!,
          feedback: _buildFeedback(child, cellTheme),
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
        color: isReorderTarget
            ? cellTheme.reorderTargetColor
            : widget.detail.selected
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
