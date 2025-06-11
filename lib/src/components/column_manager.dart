import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/models/key.dart';

final class TableColumnManager with TableCoordinatorMixin {
  TableColumnManager(List<ColumnKey>? columns) {
    _nonPinnedColumns.addAll(columns ?? []);
  }

  final _nonPinnedColumns = <ColumnKey>[];
  final _pinnedColumns = <ColumnKey>[];

  List<ColumnKey> get orderedColumns => [
        ..._pinnedColumns,
        ..._nonPinnedColumns,
      ];

  int get columnCount => _nonPinnedColumns.length + _pinnedColumns.length;

  int get pinnedColumnCount => _pinnedColumns.length;

  void reorder(ColumnKey id, int to) {
    final index = _pinnedColumns.indexWhere((c) => c == id);
    final pinned = index != -1;
    final toPinned = to < pinnedColumnCount;

    if (pinned && toPinned) {
      _pinnedColumns.removeAt(index);
      _pinnedColumns.insert(to, id);
    } else if (!pinned && !toPinned) {
      _nonPinnedColumns.removeAt(index);
      _nonPinnedColumns.insert(to - pinnedColumnCount, id);
    } else if (pinned && !toPinned) {
      _pinnedColumns.removeAt(index);
      _nonPinnedColumns.insert(to - pinnedColumnCount, id);
    } else if (!pinned && toPinned) {
      _nonPinnedColumns.removeAt(-pinnedColumnCount);
      _pinnedColumns.insert(to, id);
    }

    coordinator.notifyRebuild();
  }

  void remove(ColumnKey key) {
    final index = orderedColumns.indexWhere((c) => c == key);
    if (index == -1) return;

    if (index < pinnedColumnCount) {
      _pinnedColumns.removeAt(index);
    } else {
      _nonPinnedColumns.removeAt(index - pinnedColumnCount);
    }

    coordinator.notifyRebuild();
  }

  void add(ColumnKey id, {bool pinned = false}) {
    if (orderedColumns.contains(id)) {
      return; // Column already exists
    }

    if (pinned) {
      _pinnedColumns.add(id);
    } else {
      _nonPinnedColumns.add(id);
    }

    coordinator.notifyRebuild();
  }

  void pin(ColumnKey id) {
    final index = orderedColumns.indexWhere((c) => c == id);
    if (index == -1 || index < pinnedColumnCount) return;

    _nonPinnedColumns.removeAt(index - pinnedColumnCount);
    _pinnedColumns.add(id);
    coordinator.notifyRebuild();
  }

  void unpin(ColumnKey id) {
    final index = orderedColumns.indexWhere((c) => c == id);
    if (index == -1 || index >= pinnedColumnCount) return;

    _pinnedColumns.removeAt(index);
    _nonPinnedColumns.insert(0, id);
    coordinator.notifyRebuild();
  }

  @override
  void dispose() {
    super.dispose();
    _nonPinnedColumns.clear();
    _pinnedColumns.clear();
  }
}
