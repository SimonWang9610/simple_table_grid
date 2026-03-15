import 'package:simple_table_grid/simple_table_grid.dart';

/// Defines commands that will be dispatched by controllers
/// to notify the coordinator about certain actions or events.
sealed class CoordinatorCommand {
  const CoordinatorCommand();
}

/// Command to reset the measured extents of rows and columns,
/// which can be used when the row data or column data changes.
final class ResetExtentCommand extends CoordinatorCommand {
  final List<RowKey> evictedRowKeys;

  /// If true, all row/column extents will be reset,
  /// as the row/column data may change, which can lead to different layout results for those dynamic cells.
  final bool resetAllRows;

  /// If true, all column extents will be reset.
  /// As the column data may change, which can lead to different layout results for those dynamic cells
  final bool resetAllColumns;

  const ResetExtentCommand({
    this.evictedRowKeys = const [],
    this.resetAllRows = false,
    this.resetAllColumns = false,
  });

  bool get isAnyReset =>
      resetAllRows || resetAllColumns || evictedRowKeys.isNotEmpty;

  @override
  String toString() {
    return 'ResetExtentCommand(evictedRowKeys: $evictedRowKeys, resetAllRows: $resetAllRows, resetAllColumns: $resetAllColumns)';
  }
}
