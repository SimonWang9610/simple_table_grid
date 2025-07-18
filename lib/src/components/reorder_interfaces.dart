import 'package:simple_table_grid/simple_table_grid.dart';

mixin TableKeyReorderMixin<T extends TableKey> {
  // /// If the index of [from] is less than the index of [to], [from] will come after [to].
  // /// If the index of [from] is greater than the index of [to], [from] will come before [to].
  // /// If [from] and [to] are the same, nothing will happen.
  // void reorder(T from, T to);
  // void predicateReorder(T from, T to);

  void reordering(T from, T? to);
  void confirmReordering(bool apply);

  ReorderPredicate? get reorderPredicate;
}
