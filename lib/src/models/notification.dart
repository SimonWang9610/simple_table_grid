import 'package:simple_table_grid/simple_table_grid.dart';

/// Notification for coordinators, which can be used to notify coordinators of certain events or actions
/// that may require the coordinators to update their state or perform certain operations.
sealed class CoordinatorNotification {
  const CoordinatorNotification();
}

final class RowRemovedNotification extends CoordinatorNotification {
  final List<RowKey> rows;

  const RowRemovedNotification(this.rows);

  @override
  String toString() => 'RowRemovedNotification($rows)';
}

final class ColumnRemovedNotification extends CoordinatorNotification {
  final List<ColumnKey> columns;

  const ColumnRemovedNotification(this.columns);

  @override
  String toString() => 'ColumnRemovedNotification($columns)';
}

final class ColumnAddedNotification extends CoordinatorNotification {
  final List<ColumnKey> columns;

  const ColumnAddedNotification(this.columns);

  @override
  String toString() => 'ColumnAddedNotification($columns)';
}
