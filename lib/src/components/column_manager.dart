import 'package:simple_table_grid/src/components/coordinator.dart';
import 'package:simple_table_grid/src/components/key_ordering.dart';
import 'package:simple_table_grid/src/models/key.dart';

final class TableColumnManager with TableCoordinatorMixin {
  TableColumnManager(List<ColumnKey>? columns) {
    _nonPinnedOrdering = KeyOrdering.efficient(columns ?? <ColumnKey>[]);
  }

  final _pinnedOrdering = KeyOrdering.efficient(<ColumnKey>[]);
  late final KeyOrdering<ColumnKey> _nonPinnedOrdering;

  List<ColumnKey> get orderedColumns => [
        ..._pinnedOrdering.keys,
        ..._nonPinnedOrdering.keys,
      ];

  int get columnCount => _pinnedOrdering.length + _nonPinnedOrdering.length;

  int get pinnedColumnCount => _pinnedOrdering.length;

  void reorder(ColumnKey from, ColumnKey to) {
    final fromPinned = _pinnedOrdering.contains(from);
    final toPinned = _pinnedOrdering.contains(to);

    if (fromPinned && toPinned) {
      _pinnedOrdering.reorder(from, to);
    } else if (!fromPinned && !toPinned) {
      _nonPinnedOrdering.reorder(from, to);
    } else if (fromPinned && !toPinned) {
      _pinnedOrdering.remove(from);
      _nonPinnedOrdering.add(to);
    } else if (!fromPinned && toPinned) {
      _nonPinnedOrdering.remove(from);
      _pinnedOrdering.add(to);
    }

    coordinator.notifyRebuild();
  }

  void remove(ColumnKey key) {
    if (!_pinnedOrdering.contains(key) && !_nonPinnedOrdering.contains(key)) {
      return; // Key not found, nothing to remove
    }

    _pinnedOrdering.remove(key);
    _nonPinnedOrdering.remove(key);

    coordinator.notifyRebuild();
  }

  void add(ColumnKey key, {bool pinned = false}) {
    if (_pinnedOrdering.contains(key) || _nonPinnedOrdering.contains(key)) {
      return;
    }

    if (pinned) {
      _pinnedOrdering.add(key);
    } else {
      _nonPinnedOrdering.add(key);
    }

    coordinator.notifyRebuild();
  }

  void pin(ColumnKey key) {
    if (_pinnedOrdering.contains(key)) return;

    _nonPinnedOrdering.remove(key);
    _pinnedOrdering.add(key);

    coordinator.notifyRebuild();
  }

  void unpin(ColumnKey key) {
    if (_nonPinnedOrdering.contains(key)) return;

    _pinnedOrdering.remove(key);
    _nonPinnedOrdering.insert(0, key);

    coordinator.notifyRebuild();
  }

  @override
  void dispose() {
    super.dispose();
    _pinnedOrdering.reset();
    _nonPinnedOrdering.reset();
  }
}
