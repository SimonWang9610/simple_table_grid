import 'package:flutter/material.dart';
import 'package:simple_table_grid/custom_render/table_grid_view.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';
import 'package:simple_table_grid/src/widgets/cell_detail_widget.dart';

import 'package:simple_table_grid/simple_table_grid.dart';

class TableGrid extends StatefulWidget {
  final TableController controller;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ScrollPhysics? horizontalScrollPhysics;
  final ScrollPhysics? verticalScrollPhysics;

  /// The cell detail builder for the table cells.
  final TableCellDetailBuilder<TableCellDetail> builder;

  /// The header detail builder for the table headers.
  final TableCellDetailBuilder<TableHeaderDetail> headerBuilder;
  final TableGridThemeData theme;

  final bool resizeColumn;

  /// Whether to allow reordering of columns by dragging.
  final bool reorderColumn;

  /// Whether to allow reordering of rows by dragging.
  /// only works if the [TableController.paginator] is null.
  final bool reorderRow;

  /// Whether to allow resizing of rows by dragging.
  /// only works if the [TableController.paginator] is null.
  final bool resizeRow;

  const TableGrid({
    super.key,
    required this.controller,
    required this.builder,
    required this.headerBuilder,
    this.theme = const TableGridThemeData(),
    this.horizontalScrollController,
    this.horizontalScrollPhysics,
    this.verticalScrollController,
    this.verticalScrollPhysics,
    this.resizeColumn = true,
    this.reorderColumn = true,
    this.reorderRow = false,
    this.resizeRow = false,
  });

  @override
  State<TableGrid> createState() => _TableGridState();
}

class _TableGridState extends State<TableGrid> {
  ScrollController? _horizontalFallbackController;
  ScrollController? _verticalFallbackController;

  ScrollController get _effectiveHorizontalScrollController =>
      widget.horizontalScrollController ??
      (_horizontalFallbackController ??= ScrollController());

  ScrollController get _effectiveVerticalScrollController =>
      widget.verticalScrollController ??
      (_verticalFallbackController ??= ScrollController());

  @override
  void dispose() {
    _horizontalFallbackController?.dispose();
    _verticalFallbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grid = ListenableBuilder(
      listenable: widget.controller,
      builder: (_, __) {
        return TableGridView.withController(
          mainAxis: Axis.horizontal,
          horizontalDetails: ScrollableDetails.horizontal(
            controller: _effectiveHorizontalScrollController,
            physics:
                widget.horizontalScrollPhysics ?? const ClampingScrollPhysics(),
          ),
          verticalDetails: ScrollableDetails.vertical(
            controller: _effectiveVerticalScrollController,
            physics:
                widget.verticalScrollPhysics ?? const ClampingScrollPhysics(),
          ),
          controller: widget.controller,
          builder: _delegateBuilder,
        );
      },
    );

    final bar = Scrollbar(
      controller: _effectiveVerticalScrollController,
      child: TableGridTheme(
        data: widget.theme,
        child: grid,
      ),
    );

    return Scrollbar(
      controller: _effectiveHorizontalScrollController,
      child: bar,
    );
  }

  Widget _delegateBuilder(BuildContext context, ChildVicinity vicinity) {
    final listenable =
        widget.controller.internal.getCellFocusNotifier(vicinity);
    return listenable == null
        ? _buildCell(context, vicinity)
        : ListenableBuilder(
            listenable: listenable,
            builder: (ctx, _) => _buildCell(ctx, vicinity),
          );
  }

  Widget _buildCell(
    BuildContext context,
    ChildVicinity vicinity,
  ) {
    final rightEdge = _isRightEdge(vicinity.column);
    final bottomEdge = _isBottomEdge(vicinity.row);

    final detail = widget.controller.internal.getCellDetail(vicinity);

    return switch (detail) {
      TableHeaderDetail() => CellDetailWidget(
          isRightEdge: rightEdge,
          isBottomEdge: bottomEdge,
          detail: detail,
          builder: widget.headerBuilder,
          dragEnabled: widget.reorderColumn,
          resizeEnabled: widget.resizeColumn,
          cursorDelegate: widget.controller.sizer as TableCursorDelegate,
          onReorder: (from, to) {
            widget.controller.columns.reorder(from.columnKey, to.columnKey);
          },
        ),
      TableCellDetail() => CellDetailWidget(
          detail: detail,
          isRightEdge: rightEdge,
          isBottomEdge: bottomEdge,
          dragEnabled:
              widget.controller.paginator == null ? widget.reorderRow : false,
          resizeEnabled:
              widget.controller.paginator == null ? widget.resizeRow : false,
          cursorDelegate: widget.controller.sizer as TableCursorDelegate,
          builder: widget.builder,
          onReorder: (from, to) {
            widget.controller.rows.reorder(from.rowKey, to.rowKey);
          },
        ),
    };
  }

  bool _isBottomEdge(int row) {
    return row == widget.controller.pinnedRowCount - 1 ||
        row == widget.controller.rowCount - 1;
  }

  bool _isRightEdge(int column) {
    return column == widget.controller.columnCount - 1 ||
        column == widget.controller.pinnedColumnCount - 1;
  }
}
