import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class TableGrid extends StatelessWidget {
  final TableController controller;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final ScrollPhysics? horizontalScrollPhysics;
  final ScrollPhysics? verticalScrollPhysics;
  final TableCellDetailBuilder<TableCellDetail> cellBuilder;
  final TableCellDetailBuilder<ColumnHeaderDetail> columnBuilder;
  final WidgetBuilder? loadingBuilder;
  final TableGridBorder border;

  const TableGrid({
    super.key,
    required this.controller,
    required this.cellBuilder,
    required this.columnBuilder,
    required this.border,
    this.horizontalScrollController,
    this.horizontalScrollPhysics,
    this.verticalScrollController,
    this.verticalScrollPhysics,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) {
        return Stack(
          children: [
            TableView.builder(
              horizontalDetails: ScrollableDetails.horizontal(
                controller: horizontalScrollController,
                physics:
                    horizontalScrollPhysics ?? const ClampingScrollPhysics(),
              ),
              verticalDetails: ScrollableDetails.vertical(
                controller: verticalScrollController,
                physics: verticalScrollPhysics ?? const ClampingScrollPhysics(),
              ),
              columnCount: controller.columnCount,
              rowCount: controller.rowCount,
              pinnedColumnCount: controller.pinnedColumnCount,
              pinnedRowCount: controller.pinnedRowCount,
              columnBuilder: _buildColumn,
              rowBuilder: _buildRow,
              cellBuilder: _buildCell,
            ),
            if (controller.dataCount == 0)
              Align(
                alignment: Alignment.center,
                child: loadingBuilder?.call(context) ??
                    const CircularProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  TableSpan? _buildColumn(int index) {
    return controller.buildColumnSpan(index, border);
  }

  TableSpan? _buildRow(int index) {
    return controller.buildRowSpan(index, border);
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final listenable = controller.getCellFocusNotifier(vicinity);

    return TableViewCell(
      child: listenable != null
          ? ListenableBuilder(
              listenable: listenable,
              builder: (context, _) => _buildCellChild(context, vicinity),
            )
          : _buildCellChild(context, vicinity),
    );
  }

  Widget _buildCellChild(BuildContext context, TableVicinity vicinity) {
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
