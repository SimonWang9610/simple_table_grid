import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/header_widget.dart';
import 'package:simple_table_grid/custom_render/cell_widget.dart';

import 'package:simple_table_grid/simple_table_grid.dart';

class TableGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) {
        return TableGridView.builder(
          mainAxis: Axis.horizontal,
          horizontalDetails: ScrollableDetails.horizontal(
            controller: horizontalScrollController,
            physics: horizontalScrollPhysics ?? const ClampingScrollPhysics(),
          ),
          verticalDetails: ScrollableDetails.vertical(
            controller: verticalScrollController,
            physics: verticalScrollPhysics ?? const ClampingScrollPhysics(),
          ),
          columnCount: controller.columnCount,
          rowCount: controller.rowCount,
          pinnedColumnCount: controller.pinnedColumnCount,
          pinnedRowCount: controller.pinnedRowCount,
          rowExtentBuilder: (index) {
            return controller.sizer.getRowExtent(index);
          },
          columnExtentBuilder: (index) {
            return controller.sizer.getColumnExtent(index);
          },
          builder: (_, vicinity) {
            final listenable =
                controller.internal.getCellFocusNotifier(vicinity);
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
  }

  Widget _buildCell(
    BuildContext context,
    ChildVicinity vicinity,
  ) {
    final rightEdge = _isRightEdge(vicinity.column);
    final bottomEdge = _isBottomEdge(vicinity.row);

    final cellBorder = border.calculateBorder(rightEdge, bottomEdge);
    final padding = border.calculatePadding(rightEdge, bottomEdge);

    final detail = controller.internal.getCellDetail(vicinity);

    return switch (detail) {
      ColumnHeaderDetail() => HeaderWidget(
          isMiddleHeader: vicinity.column > 0 &&
              vicinity.column < controller.columnCount - 1,
          border: cellBorder,
          padding: padding,
          detail: detail,
          builder: headerBuilder,
          sizer: controller.sizer,
        ),
      TableCellDetail() => CellWidget(
          border: cellBorder,
          padding: padding,
          detail: detail,
          builder: builder,
        ),
    };
  }

  bool _isBottomEdge(int row) {
    return row == controller.pinnedRowCount - 1 ||
        row == controller.rowCount - 1;
  }

  bool _isRightEdge(int column) {
    return column == controller.columnCount - 1 ||
        column == controller.pinnedColumnCount - 1;
  }
}
