import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/simple_table_grid.dart';

class CellTheme {
  final Color? hoveringColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  /// The color used to indicate the cell is a reorder target.
  /// This color is used when the cell is being dragged over a reorder target.
  final Color? reorderTargetColor;

  const CellTheme({
    this.hoveringColor,
    this.selectedColor,
    this.unselectedColor,
    this.reorderTargetColor,
  });
}

/// Represents the theme data for the table grid, including cell themes and borders.
/// This class allows customization of the appearance of cells and headers in the table grid.
///
/// Note: users must update the hovering status programmatically by using the [TableController.focuser]
class TableGridThemeData {
  /// The theme for regular cells in the table grid.
  final CellTheme cellTheme;

  /// The theme for header cells in the table grid.
  final CellTheme headerTheme;

  /// The border for the table grid.
  final TableGridBorder? border;

  /// The border for reorder targets in the table grid.
  /// This border is used to visually indicate where a cell is targeted for reordering.
  final TableGridBorder? reorderTargetBorder;

  const TableGridThemeData({
    this.cellTheme = const CellTheme(),
    this.headerTheme = const CellTheme(),
    this.border,
    this.reorderTargetBorder,
  });

  EdgeInsets? calculatePadding(
    bool rightEdge,
    bool bottomEdge,
    bool isReorderTarget,
  ) {
    if (isReorderTarget && reorderTargetBorder != null) {
      return reorderTargetBorder!.calculatePadding(rightEdge, bottomEdge);
    }

    return border?.calculatePadding(rightEdge, bottomEdge);
  }

  Border? calculateBorder(
    bool rightEdge,
    bool bottomEdge,
    bool isReorderTarget,
  ) {
    if (isReorderTarget && reorderTargetBorder != null) {
      return reorderTargetBorder!.calculateBorder(rightEdge, bottomEdge);
    }

    return border?.calculateBorder(rightEdge, bottomEdge);
  }
}

class TableGridTheme extends InheritedWidget {
  final TableGridThemeData data;

  const TableGridTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static TableGridThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<TableGridTheme>();
    if (theme == null) {
      throw FlutterError('TableGridTheme not found in context');
    }
    return theme.data;
  }

  @override
  bool updateShouldNotify(TableGridTheme oldWidget) => data != oldWidget.data;
}
