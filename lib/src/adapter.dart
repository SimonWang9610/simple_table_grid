import 'package:simple_table_grid/simple_table_grid.dart';

abstract base class DataAdapter {
  RowData toRowData(Object data);
  List<RowData> sort(List<RowData> oldRows);
}
