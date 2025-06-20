import 'package:flutter/material.dart';
import 'package:simple_table_grid/src/controllers/misc.dart';
import 'package:simple_table_grid/src/widgets/cell_detail_widget.dart';

import 'package:simple_table_grid/simple_table_grid.dart';

class TableGrid extends StatefulWidget {
  final TableController controller;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ScrollPhysics? horizontalScrollPhysics;
  final ScrollPhysics? verticalScrollPhysics;
  final TableCellDetailBuilder<TableCellDetail> builder;
  final TableCellDetailBuilder<TableHeaderDetail> headerBuilder;
  final TableGridThemeData theme;

  /// Whether to allow resizing of columns.
  ///
  /// If the extent of the dragging column does not accept the delta,
  /// it will not change the extent.
  ///
  /// Typically, the column extent must be [Extent.range] to accept the delta.
  final bool resizeColumn;

  /// Whether to allow resizing of rows.
  ///
  /// If the extent of the dragging row does not accept the delta,
  /// it will not change the extent.
  ///
  /// Typically, the row extent must be [Extent.range] to accept the delta.
  final bool resizeRow;

  /// Whether to allow reordering of columns by dragging.
  final bool reorderColumn;

  /// Whether to allow reordering of rows by dragging.
  final bool reorderRow;

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
    this.resizeRow = false,
    this.reorderRow = false,
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
        return TableGridView.builder(
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
          columnCount: widget.controller.columnCount,
          rowCount: widget.controller.rowCount,
          pinnedColumnCount: widget.controller.pinnedColumnCount,
          pinnedRowCount: widget.controller.pinnedRowCount,
          rowExtentBuilder: (index) {
            return widget.controller.sizer.getRowExtent(index);
          },
          columnExtentBuilder: (index) {
            return widget.controller.sizer.getColumnExtent(index);
          },
          builder: (_, vicinity) {
            final listenable =
                widget.controller.internal.getCellFocusNotifier(vicinity);
            return listenable == null
                ? _buildCell(context, vicinity)
                : ListenableBuilder(
                    listenable: listenable,
                    builder: (ctx, _) => _buildCell(ctx, vicinity),
                  );
          },
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
          dragEnabled: widget.reorderRow,
          resizeEnabled: widget.resizeRow,
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
