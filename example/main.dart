import 'package:flatbush_dart/flatbush_dart.dart';

void main() {
  final items = <List<double>>[
    [0, 0, 1, 1],
    [1, 1, 2, 2],
    [2, 2, 3, 3],
    [3, 3, 4, 4],
    [4, 4, 5, 5],
    [5, 5, 6, 6],
    [6, 6, 7, 7],
    [7, 7, 8, 8],
    [8, 8, 9, 9],
    [9, 9, 10, 10],
  ];

  // Initialize Flatbush for a given number type and number of items
  final index = Flatbush.double64(10);

  // fill it with the items
  for (final p in items) {
    index.add(
      minX: p[0],
      minY: p[1],
      maxX: p[2],
      maxY: p[3],
    );
  }

  // perform the indexing
  index.finish();

  // make a bounding box query
  index.search(minX: 5, minY: 5, maxX: 7, maxY: 7).map((i) => items[i]);

  /// result:
  /// [
  ///   [4.0, 4.0, 5.0, 5.0],
  ///   [5.0, 5.0, 6.0, 6.0],
  ///   [6.0, 6.0, 7.0, 7.0],
  ///   [7.0, 7.0, 8.0, 8.0]
  /// ]
}
