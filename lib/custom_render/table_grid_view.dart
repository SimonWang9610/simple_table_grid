import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/custom_render/delegate.dart';
import 'package:simple_table_grid/custom_render/viewport.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

extension ChildVicinityGridExt on ChildVicinity {
  int get row => yIndex;
  int get column => xIndex;
}

class TableGridView extends TwoDimensionalScrollView {
  const TableGridView({
    super.key,
    super.primary,
    super.mainAxis,
    super.horizontalDetails,
    super.verticalDetails,
    super.cacheExtent,
    required CellLayoutExtentDelegate super.delegate,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.clipBehavior,
  });

  TableGridView.builder({
    super.key,
    super.primary,
    super.mainAxis,
    super.horizontalDetails,
    super.verticalDetails,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.clipBehavior,
    required int columnCount,
    required int rowCount,
    int pinnedColumnCount = 0,
    int pinnedRowCount = 0,
    required CellExtentBuilder rowExtentBuilder,
    required CellExtentBuilder columnExtentBuilder,
    required CellWidgetBuilder builder,
  })  : assert(pinnedColumnCount >= 0),
        assert(pinnedRowCount >= 0),
        assert(rowCount >= 0),
        assert(columnCount >= 0),
        assert(pinnedColumnCount <= columnCount),
        assert(pinnedRowCount <= rowCount),
        super(
          delegate: TableGridCellBuilderDelegate(
            columnCount: columnCount,
            rowCount: rowCount,
            builder: builder,
            pinnedColumnCount: pinnedColumnCount,
            pinnedRowCount: pinnedRowCount,
            rowExtentBuilder: rowExtentBuilder,
            columnExtentBuilder: columnExtentBuilder,
          ),
        );

  TableGridView.withController({
    super.key,
    super.primary,
    super.mainAxis,
    super.horizontalDetails,
    super.verticalDetails,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.clipBehavior,
    required CellWidgetBuilder builder,
    required TableController controller,
  }) : super(
          delegate: TableGridCellBuilderDelegate(
            columnCount: controller.columns.count,
            rowCount: controller.rows.count,
            builder: builder,
            pinnedColumnCount: controller.columns.pinnedCount,
            pinnedRowCount: controller.rows.pinnedCount,
            rowExtentBuilder: controller.sizer.getRowExtent,
            columnExtentBuilder: controller.sizer.getColumnExtent,
          ),
        );

  @override
  TableGridViewport buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return TableGridViewport(
      verticalOffset: verticalOffset,
      horizontalOffset: horizontalOffset,
      verticalAxisDirection: verticalDetails.direction,
      horizontalAxisDirection: horizontalDetails.direction,
      delegate: delegate as CellLayoutExtentDelegate,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}
