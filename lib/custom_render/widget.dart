import 'package:flutter/material.dart';
import 'package:simple_table_grid/custom_render/layout_extent_delegate.dart';
import 'package:simple_table_grid/custom_render/table_grid_view.dart';
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: ListenableBuilder(
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
                  ? _buildCellChild(context, vicinity)
                  : ListenableBuilder(
                      listenable: listenable,
                      builder: (ctx, _) => _buildCellChild(ctx, vicinity),
                    );
            },
          );
        },
      ),
    );
  }

  Widget _buildCellChild(BuildContext context, ChildVicinity vicinity) {
    final detail = controller.getCellDetail(vicinity);

    final child = switch (detail) {
      ColumnHeaderDetail() => columnBuilder(context, detail),
      TableCellDetail() => cellBuilder(context, detail),
    };

    return KeyedSubtree(
      // key: ValueKey(detail),
      child: child,
    );
  }
}
