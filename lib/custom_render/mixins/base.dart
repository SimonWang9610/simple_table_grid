import 'package:flutter/painting.dart';
import 'package:simple_table_grid/custom_render/delegate.dart';
import 'package:simple_table_grid/custom_render/layout_metrics.dart';

abstract mixin class TableViewportMetrics {
  Span? getRowSpan(int rowIndex);
  Span? getColumnSpan(int columnIndex);

  double get verticalBorderWidth => _extractBorderWidth(verticalBorderSide);

  double get horizontalBorderWidth => _extractBorderWidth(horizontalBorderSide);

  BorderSide get verticalBorderSide;
  BorderSide get horizontalBorderSide;

  CellLayoutExtentDelegate get delegate;
}

double _extractBorderWidth(BorderSide side) {
  if (side.style == BorderStyle.none) {
    return 0;
  }

  return switch (side.strokeAlign) {
    BorderSide.strokeAlignInside => side.width,
    _ => side.width / 2,
  };
}
