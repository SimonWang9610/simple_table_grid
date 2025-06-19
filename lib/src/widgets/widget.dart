import 'package:flutter/material.dart';
import 'package:simple_table_grid/src/widgets/header_widget.dart';
import 'package:simple_table_grid/src/widgets/cell_widget.dart';

import 'package:simple_table_grid/simple_table_grid.dart';

class TableGrid extends StatefulWidget {
  final TableController controller;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ScrollPhysics? horizontalScrollPhysics;
  final ScrollPhysics? verticalScrollPhysics;
  final TableCellDetailBuilder<TableCellDetail> builder;
  final TableCellDetailBuilder<ColumnHeaderDetail> headerBuilder;
  final TableGridBorder border;
  final bool resizeColumn;
  final bool resizeRow;

  const TableGrid({
    super.key,
    required this.controller,
    required this.builder,
    required this.headerBuilder,
    required this.border,
    this.horizontalScrollController,
    this.horizontalScrollPhysics,
    this.verticalScrollController,
    this.verticalScrollPhysics,
    this.resizeColumn = true,
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
      child: grid,
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

    final cellBorder = widget.border.calculateBorder(rightEdge, bottomEdge);
    final padding = widget.border.calculatePadding(rightEdge, bottomEdge);

    final detail = widget.controller.internal.getCellDetail(vicinity);

    return switch (detail) {
      ColumnHeaderDetail() => HeaderWidget(
          border: cellBorder,
          padding: padding,
          detail: detail,
          builder: widget.headerBuilder,
          sizer: widget.controller.sizer,
          onReorder: (from, to) {
            widget.controller.columns.reorder(from.columnKey, to.columnKey);
          },
        ),
      TableCellDetail() => CellWidget(
          border: cellBorder,
          padding: padding,
          detail: detail,
          builder: widget.builder,
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
