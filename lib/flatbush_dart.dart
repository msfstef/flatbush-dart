/// Fast spatial index for 2D points and rectangles.
abstract class Flatbush {
  /// Creates a new index that will hold [numItems] number of
  /// rectangles.
  ///
  /// The [nodeSize] parameter controls the size of the tree
  /// node ([defaultNodeSize] by default). Increasing this value
  /// makes indexing faster and queries slower, and vice versa.
  const Flatbush({
    required this.numItems,
    this.nodeSize = defaultNodeSize,
  });

  /// Default size of the tree node.
  static const int defaultNodeSize = 16;

  /// The number of items the index will hold.
  final int numItems;

  /// Size of the tree node of the index.
  final int nodeSize;

  /// Adds a given rectangle to the index, returns
  /// the corresponding [ItemIdx] for the added item.
  ItemIdx add({
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
  });

  /// Performs indexing of the added rectangles.
  /// The number of rectangles added must match the one specified
  void finish();

  /// Returns an array of item indices intersecting or touching
  /// the given bounding box, specified by [minX], [minY], [maxX], [maxY].
  ///
  /// Item indices refer to the value returned by [add].
  List<ItemIdx> search({
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
    FlatbushFilter? filter,
  });

  /// Returns an array of item indices in order of distance for the
  /// given coordinates [x] and [y] (using K nearest neighbors search).
  ///
  /// The [maxResults] parameter limits the number of results returned,
  /// if nothing is provided then all results are returned.
  ///
  /// The [maxDistance] parameter limits the distance from the given
  /// coordinate to the results returned. Set to [double.infinity] by
  /// default.
  ///
  /// The [filter] parameter can be used to filter the results based
  /// on their [ItemIdx].
  List<ItemIdx> neighbours(
    double x,
    double y, {
    int? maxResults,
    double maxDistance = double.infinity,
    FlatbushFilter? filter,
  });
}

/// The index of an item as returned by [Flatbush.add]
/// when the item is added to the index.
typedef ItemIdx = int;

/// A function that filters the results of a search
/// based on the [index] of the item.
typedef FlatbushFilter = bool Function(ItemIdx index);
