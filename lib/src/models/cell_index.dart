class CellIndex {
  final int row;
  final int column;

  const CellIndex(this.row, this.column)
      : assert(row >= 0 && column >= 0, "row and column must be non-negative");

  @override
  bool operator ==(covariant CellIndex other) {
    if (identical(this, other)) return true;

    return other.row == row && other.column == column;
  }

  @override
  int get hashCode => row.hashCode ^ column.hashCode;

  @override
  String toString() => 'CellIndex(row: $row, column: $column)';
}
