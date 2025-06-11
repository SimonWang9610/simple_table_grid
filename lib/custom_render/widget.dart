import 'package:flutter/material.dart';
import 'package:simple_table_grid/custom_render/column_header_widget.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class TableGrid extends StatelessWidget {
  final TableController controller;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ScrollPhysics? horizontalScrollPhysics;
  final ScrollPhysics? verticalScrollPhysics;
  final TableCellDetailBuilder<TableCellDetail> cellBuilder;
  final TableCellDetailBuilder<ColumnHeaderDetail> columnBuilder;
  const TableGrid({
    super.key,
    required this.controller,
    required this.cellBuilder,
    required this.columnBuilder,
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
          builder: (_, vicinity) => CellWidget(
            vicinity: vicinity,
            builder: cellBuilder,
            headerBuilder: columnBuilder,
            controller: controller,
          ),
        );
      },
    );
  }

  // Widget _buildCellChild(BuildContext context, ChildVicinity vicinity) {
  //   final detail = controller.getCellDetail(vicinity);

  //   final (key, child) = switch (detail) {
  //     ColumnHeaderDetail() => (
  //         detail.columnKey,
  //         columnBuilder(context, detail)
  //       ),
  //     TableCellDetail() => (detail.cellKey, cellBuilder(context, detail)),
  //   };

  //   return KeyedSubtree(
  //     key: ValueKey(key),
  //     child: child,
  //   );
  // }
}
