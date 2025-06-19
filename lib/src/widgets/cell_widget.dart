import 'package:flutter/material.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class CellWidget extends StatelessWidget {
  final Border? border;
  final EdgeInsets? padding;
  final TableCellDetail detail;
  final TableCellDetailBuilder<TableCellDetail> builder;

  const CellWidget({
    super.key,
    this.border,
    this.padding,
    required this.detail,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = builder(context, detail);

    if (padding != null) {
      child = Padding(
        padding: padding!,
        child: child,
      );
    }

    if (border != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          border: border,
        ),
        child: child,
      );
    }

    return child;
  }
}
