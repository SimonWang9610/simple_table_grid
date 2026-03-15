import 'package:flutter/foundation.dart';

class Span with Diagnosticable {
  late double _leadingOffset;
  late double _extent;
  late bool _isPinned;

  double get leadingOffset => _leadingOffset;
  double get extent => _extent;

  double get trailingOffset => _leadingOffset + _extent;

  bool get isPinned => _isPinned;

  void update({
    required double leadingOffset,
    required double extent,
    required bool isPinned,
  }) {
    _leadingOffset = leadingOffset;
    _extent = extent;
    _isPinned = isPinned;
  }
}

class LayoutMetrics {
  final Map<int, Span> _metrics = {};

  int? _firstNonPinned;
  int? _lastNonPinned;

  Span? remove(int index) {
    return _metrics.remove(index);
  }

  void set(int index, Span span) {
    _metrics[index] = span;
  }

  void resetRange() {
    _firstNonPinned = null;
    _lastNonPinned = null;
  }

  void clear() {
    _metrics.clear();
    resetRange();
  }

  Span? operator [](int index) {
    return _metrics[index];
  }

  int get length => _metrics.length;

  bool get isEmpty => _metrics.isEmpty;

  int? get firstNonPinned => _firstNonPinned;
  set firstNonPinned(int? value) {
    if (_firstNonPinned != null || value == null) {
      return;
    }

    _firstNonPinned = value;
  }

  int? get lastNonPinned => _lastNonPinned;
  set lastNonPinned(int? value) {
    if (_firstNonPinned == null || _lastNonPinned != null || value == null) {
      return;
    }

    assert(
      value >= _firstNonPinned!,
      "the last value must be greater than the first",
    );

    _lastNonPinned = value;
  }

  bool get isRangeEmpty => _firstNonPinned == null && _lastNonPinned == null;

  double? getNonPinnedOffset(double viewportOffset, double pinnedExtent) {
    if (_firstNonPinned == null) return null;

    return viewportOffset -
        _metrics[_firstNonPinned!]!.leadingOffset -
        pinnedExtent;
  }
}
