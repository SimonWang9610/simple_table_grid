import 'package:simple_table_grid/simple_table_grid.dart';

abstract class KeyOrdering<T extends TableKey> {
  void add(T key);
  void insert(int index, T key);
  void remove(T key);
  void reorder(T from, T to);
  void reset();

  ReorderPredicate<T>? predicate(T from, T to);
  bool contains(T key);

  int? indexOf(T key);

  T? operator [](int index);

  List<T> get keys;
  T? get firstKey;
  T? get lastKey;

  int get length;

  const KeyOrdering();

  factory KeyOrdering.quick(List<T> keys) {
    return QuickOrdering<T>(keys);
  }

  factory KeyOrdering.efficient(List<T> keys) {
    return EfficientOrdering<T>(keys);
  }
}

class QuickOrdering<T extends TableKey> extends KeyOrdering<T> {
  final _keyOrdering = <T, int>{};
  final _indexOrdering = <int, T>{};

  QuickOrdering(List<T> keys) {
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      _keyOrdering[key] = i;
      _indexOrdering[i] = key;
    }
  }

  @override
  int? indexOf(T key) {
    if (!_keyOrdering.containsKey(key)) return null;

    final index = _keyOrdering[key];
    assert(
      index != null && _indexOrdering[index] == key,
      "Key $key at index $index does not match the ordering",
    );
    return index;
  }

  @override
  T? operator [](int index) {
    assert(
      index >= 0 && index < _indexOrdering.length,
      "Index $index is out of bounds for the ordering, must be between 0 and ${_indexOrdering.length - 1}",
    );
    return _indexOrdering[index];
  }

  @override
  int get length {
    assert(
      _keyOrdering.length == _indexOrdering.length,
      "Key ordering and index ordering must have the same length",
    );
    return _keyOrdering.length;
  }

  @override
  bool contains(T key) {
    final contained = _keyOrdering.containsKey(key);

    assert(
      !contained || _indexOrdering[_keyOrdering[key]!] == key,
      "Key $key is in the ordering but does not match its index",
    );

    return contained;
  }

  @override
  void add(T key) {
    if (_keyOrdering.containsKey(key)) return;

    final newIndex = _keyOrdering.length;
    _keyOrdering[key] = newIndex;
    _indexOrdering[newIndex] = key;
  }

  @override
  void insert(int index, T key) {
    if (_keyOrdering.containsKey(key)) return;

    final to = _indexOrdering[index];

    if (to == null) {
      // If the index is out of bounds, just add at the end
      add(key);
      return;
    }

    /// we need to iterate backwards to avoid overwriting keys
    for (int i = _indexOrdering.length - 1; i >= index; i--) {
      final currentKey = _indexOrdering[i];
      if (currentKey != null) {
        _keyOrdering[currentKey] = i + 1;
        _indexOrdering[i + 1] = currentKey;
      } else {
        _indexOrdering.remove(i);
      }
    }

    _keyOrdering[key] = index;
    _indexOrdering[index] = key;
  }

  @override
  void remove(T key) {
    if (!_keyOrdering.containsKey(key)) return;

    final index = _keyOrdering[key]!;
    _keyOrdering.remove(key);

    assert(
      _indexOrdering[index] == key,
      "Key at index $index does not match the provided key",
    );

    _indexOrdering.remove(index);

    // Update indices of all keys after the removed key
    for (int i = index; i < _indexOrdering.length; i++) {
      final nextKey = _indexOrdering[i + 1];
      if (nextKey != null) {
        // shift the previous key down
        _keyOrdering[nextKey] = i;
        _indexOrdering[i] = nextKey;
      } else {
        // remove the last one
        _indexOrdering.remove(i);
      }
    }
  }

  @override
  void reorder(T from, T to) {
    if (from == to ||
        !_keyOrdering.containsKey(from) ||
        !_keyOrdering.containsKey(to)) {
      return;
    }

    final fromIndex = _keyOrdering[from]!;
    final toIndex = _keyOrdering[to]!;

    if (fromIndex < toIndex) {
      // Shift keys down
      for (int i = fromIndex; i < toIndex; i++) {
        final key = _indexOrdering[i + 1];
        if (key != null) {
          _keyOrdering[key] = i;
          _indexOrdering[i] = key;
        }
      }
    } else {
      // Shift keys up
      for (int i = fromIndex; i > toIndex; i--) {
        final key = _indexOrdering[i - 1];
        if (key != null) {
          _keyOrdering[key] = i;
          _indexOrdering[i] = key;
        }
      }
    }

    _keyOrdering[from] = toIndex;
    _indexOrdering[toIndex] = from;
  }

  @override
  ReorderPredicate<T>? predicate(T from, T to) {
    if (from == to ||
        !_keyOrdering.containsKey(from) ||
        !_keyOrdering.containsKey(to)) {
      return null;
    }

    final fromIndex = _keyOrdering[from]!;
    final toIndex = _keyOrdering[to]!;

    return ReorderPredicate<T>(
      candidate: to,
      afterCandidate: fromIndex < toIndex,
    );
  }

  @override
  List<T> get keys {
    final sorted = <T>[];

    for (int i = 0; i < _keyOrdering.length; i++) {
      final key = _indexOrdering[i];

      assert(
        key == null || _keyOrdering[key] == i,
        "Key at index $i does not match its ordering index",
      );

      if (key != null) {
        sorted.add(key);
      }
    }
    return sorted;
  }

  @override
  T? get firstKey {
    final key = _indexOrdering[0];

    assert(key == null || _keyOrdering[key] == 0,
        "First key does not match its index in the ordering");

    return key;
  }

  @override
  T? get lastKey {
    final lastIndex = _keyOrdering.length - 1;
    final key = _indexOrdering[lastIndex];

    assert(key == null || _keyOrdering[key] == lastIndex,
        "Last key does not match its index in the ordering");

    return key;
  }

  @override
  void reset() {
    _keyOrdering.clear();
    _indexOrdering.clear();
  }
}

class EfficientOrdering<T extends TableKey> extends KeyOrdering<T> {
  final _keys = <T>[];

  EfficientOrdering(List<T> keys) {
    _keys.addAll(keys);
  }

  @override
  int? indexOf(T key) {
    final index = _keys.indexOf(key);
    if (index == -1) return null;

    assert(
      _keys[index] == key,
      "Key at index $index does not match the provided key",
    );
    return index;
  }

  @override
  T? operator [](int index) {
    assert(
      index >= 0 && index < _keys.length,
      "Index $index is out of bounds for the ordering",
    );
    return _keys[index];
  }

  @override
  int get length => _keys.length;

  @override
  bool contains(T key) {
    final contained = _keys.contains(key);
    return contained;
  }

  @override
  void add(T key) {
    if (!_keys.contains(key)) {
      _keys.add(key);
    }
  }

  @override
  void insert(int index, T key) {
    if (_keys.contains(key)) return;

    if (index < 0 || index > _keys.length) {
      throw RangeError.index(index, _keys, "Index out of bounds");
    }

    _keys.insert(index, key);
  }

  @override
  void remove(T key) {
    _keys.remove(key);
  }

  @override
  void reorder(T from, T to) {
    if (from == to) {
      return; // No need to reorder if the keys are the same
    }

    final fromIndex = _keys.indexOf(from);
    final toIndex = _keys.indexOf(to);

    assert(
      fromIndex != -1 && toIndex != -1,
      "Both keys must be present in the ordering",
    );

    _keys.removeAt(fromIndex);

    _keys.insert(toIndex, from);
  }

  @override
  ReorderPredicate<T>? predicate(T from, T to) {
    if (from == to || !_keys.contains(from) || !_keys.contains(to)) {
      return null;
    }

    final fromIndex = _keys.indexOf(from);
    final toIndex = _keys.indexOf(to);

    return ReorderPredicate<T>(
      candidate: to,
      afterCandidate: fromIndex < toIndex,
    );
  }

  @override
  List<T> get keys => List.of(_keys);

  @override
  T? get firstKey => _keys.isNotEmpty ? _keys.first : null;

  @override
  T? get lastKey => _keys.isNotEmpty ? _keys.last : null;

  @override
  void reset() {
    _keys.clear();
  }
}
