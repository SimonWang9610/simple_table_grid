import 'package:flutter/widgets.dart';
import 'package:simple_table_grid/src/models/key.dart';

sealed class Focuser<T extends TableKey> with ChangeNotifier {
  List<T> get focused;

  bool isFocused(T value);

  void focus(T key);
  void focusAll(Iterable<T> keys, {bool shouldNotify = true});

  void unfocus(T key);
  void unfocusAll(Iterable<T> keys, {bool shouldNotify = true});

  void reset();
}

final class KeyFocuser<T extends TableKey> extends Focuser<T> {
  final Set<T> _focused = {};

  KeyFocuser({
    List<T>? focusedLines,
  }) {
    if (focusedLines != null) {
      _focused.addAll(focusedLines);
    }
  }

  @override
  List<T> get focused => List.unmodifiable(_focused);

  @override
  bool isFocused(T value) {
    return _focused.contains(value);
  }

  @override
  void focus(T key) {
    if (_focused.add(key)) {
      notifyListeners();
    }
  }

  @override
  void focusAll(Iterable<T> keys, {bool shouldNotify = true}) {
    bool anyFocused = false;

    for (final key in keys) {
      anyFocused |= _focused.add(key);
    }

    if (shouldNotify && anyFocused) {
      notifyListeners();
    }
  }

  @override
  void unfocus(T key) {
    if (_focused.remove(key)) {
      notifyListeners();
    }
  }

  @override
  void unfocusAll(Iterable<T> keys, {bool shouldNotify = true}) {
    bool anyUnfocused = false;

    for (final key in keys) {
      anyUnfocused |= _focused.remove(key);
    }

    if (shouldNotify && anyUnfocused) {
      notifyListeners();
    }
  }

  @override
  void reset() {
    if (_focused.isNotEmpty) {
      _focused.clear();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _focused.clear();
    super.dispose();
  }
}
