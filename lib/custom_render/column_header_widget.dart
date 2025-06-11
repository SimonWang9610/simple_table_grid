import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class CellWidget extends StatelessWidget {
  final ChildVicinity vicinity;
  final TableCellDetailBuilder<ColumnHeaderDetail> headerBuilder;
  final TableCellDetailBuilder<TableCellDetail> builder;
  final TableController controller;
  const CellWidget({
    super.key,
    required this.vicinity,
    required this.builder,
    required this.headerBuilder,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bottom =
        _isVerticalBottomEdge ? BorderSide(width: 2) : BorderSide.none;
    final right =
        _isHorizontalRightEdge ? BorderSide(width: 2) : BorderSide.none;

    final listenable = controller.getCellFocusNotifier(vicinity);

    return DecoratedBox(
      // key: ValueKey(key),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(width: 2),
          right: right,
          top: BorderSide(width: 2),
          bottom: bottom,
        ),
        // borderRadius: _isCorner ? BorderRadius.circular(8) : null,
        borderRadius: _isCorner
            ? BorderRadius.only(
                topLeft: Radius.circular(_isTopLeftCorner ? 8 : 0),
                topRight: Radius.circular(_isTopRightCorner ? 8 : 0),
                bottomLeft: Radius.circular(_isBottomLeftCorner ? 8 : 0),
                bottomRight: Radius.circular(_isBottomRightCorner ? 8 : 0),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 2,
          right: _isHorizontalRightEdge ? 2 : 0,
          top: 2,
          bottom: _isVerticalBottomEdge ? 2 : 0,
        ),
        child: listenable == null
            ? _buildCellChild(context, vicinity)
            : ListenableBuilder(
                listenable: listenable,
                builder: (ctx, _) => _buildCellChild(ctx, vicinity),
              ),
      ),
    );
  }

  Widget _buildCellChild(BuildContext context, ChildVicinity vicinity) {
    final detail = controller.getCellDetail(vicinity);

    final (key, child) = switch (detail) {
      ColumnHeaderDetail() => (
          detail.columnKey,
          headerBuilder(context, detail)
        ),
      TableCellDetail() => (detail.cellKey, builder(context, detail)),
    };

    return KeyedSubtree(
      key: ValueKey(key),
      child: child,
    );
  }

  bool get _isVerticalBottomEdge {
    return vicinity.row == controller.pinnedRowCount - 1 ||
        vicinity.row == controller.rowCount - 1;
  }

  bool get _isHorizontalRightEdge {
    return vicinity.column == controller.columnCount - 1 ||
        vicinity.column == controller.pinnedColumnCount - 1;
  }

  bool get _isTopLeftCorner {
    return vicinity.row == 0 && vicinity.column == 0;
  }

  bool get _isTopRightCorner {
    return vicinity.row == 0 && vicinity.column == controller.columnCount - 1;
  }

  bool get _isBottomLeftCorner {
    return vicinity.row == controller.pinnedRowCount - 1 &&
        vicinity.column == 0;
  }

  bool get _isBottomRightCorner {
    return vicinity.row == controller.pinnedRowCount - 1 &&
        vicinity.column == controller.columnCount - 1;
  }

  bool get _isCorner {
    return _isTopLeftCorner ||
        _isTopRightCorner ||
        _isBottomLeftCorner ||
        _isBottomRightCorner;
  }
}
