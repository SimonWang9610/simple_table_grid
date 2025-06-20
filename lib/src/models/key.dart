sealed class TableKey {
  const TableKey();
}

final class ColumnKey extends TableKey {
  final String id;

  const ColumnKey(this.id);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColumnKey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ColumnKey(id: $id)';
}

final class RowKey extends TableKey {
  final Object id;

  const RowKey(this.id);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RowKey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RowKey(id: $id)';
}

final class CellKey extends TableKey {
  final RowKey rowKey;
  final ColumnKey columnKey;

  const CellKey(this.rowKey, this.columnKey);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CellKey &&
        other.rowKey == rowKey &&
        other.columnKey == columnKey;
  }

  @override
  int get hashCode => rowKey.hashCode ^ columnKey.hashCode;

  @override
  String toString() =>
      'CellKey(rowKey: ${rowKey.id}, columnKey: ${columnKey.id})';
}

/// Represents a single row of data in the table.
class RowData {
  /// Unique identifier for the row.
  final RowKey key;

  /// Map of column keys to their corresponding data values for this row.
  ///
  /// Note: the value of a column key may be null if the column does not have data for this row.
  ///
  /// Like c newly column added but the values for existing rows are not set yet.
  final Map<ColumnKey, dynamic> data;

  const RowData(
    this.key, {
    required this.data,
  });

  dynamic operator [](ColumnKey columnKey) {
    return data[columnKey];
  }

  Set<ColumnKey> get columns => data.keys.toSet();
}
