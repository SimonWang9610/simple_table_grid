import 'package:simple_table_grid/simple_table_grid.dart';

/// Represents an update operation on a row in the table.
sealed class RowUpdate {
  final RowKey key;
  const RowUpdate(this.key);

  /// Applies the update to the given [row] and returns a new [RowData] instance.
  RowData apply(RowData row);
}

final class MergeColumns extends RowUpdate {
  final Map<ColumnKey, dynamic> values;

  const MergeColumns(
    super.key, {
    required this.values,
  });

  @override
  RowData apply(RowData row) {
    assert(row.key == key, 'Row key mismatch: ${row.key} != $key');

    final updatedValues = {
      ...row.data,
      ...values,
    };

    return RowData(
      row.key,
      data: updatedValues,
    );
  }
}

final class RemoveColumns extends RowUpdate {
  final List<ColumnKey> columns;

  const RemoveColumns(
    super.key, {
    required this.columns,
  });

  @override
  RowData apply(RowData row) {
    assert(row.key == key, 'Row key mismatch: ${row.key} != $key');

    final data = Map.of(row.data);

    for (final columnKey in columns) {
      data.remove(columnKey);
    }

    return RowData(
      row.key,
      data: data,
    );
  }
}
