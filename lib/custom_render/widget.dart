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
            return Extent.fixed(60);
          },
          columnExtentBuilder: (index) => Extent.fixed(100),
          builder: (_, vicinity) {
            final listenable = controller.getCellFocusNotifier(vicinity);
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

    final detail = controller.getCellDetail(vicinity);

    return switch (detail) {
      ColumnHeaderDetail() => HeaderWidget(
          isMiddleHeader: !rightEdge && vicinity.column > 0,
          border: cellBorder,
          padding: padding,
          detail: detail,
          builder: headerBuilder,
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
