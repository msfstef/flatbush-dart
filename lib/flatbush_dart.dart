import 'dart:typed_data';

/// Fast spatial index for 2D points and rectangles.
abstract class Flatbush {
  /// Creates a new index that will hold [numItems] number of
  /// rectangles.
  ///
  /// The [nodeSize] parameter controls the size of the tree
  /// node ([defaultNodeSize] by default). Increasing this value
  /// makes indexing faster and queries slower, and vice versa.
  Flatbush({
    required this.numItems,
    this.nodeSize = defaultNodeSize,
    this.coordinateArrayViewConstructor = Float64List.view,
  }) {
    if (numItems <= 0) {
      throw ArgumentError('Received non-positive numItems value: $numItems.');
    }

    if (nodeSize <= 2 || nodeSize >= 65535) {
      throw ArgumentError(
        'Received invalid nodeSize value: $nodeSize.'
        ' Must be between 2 and 2^16 - 1.',
      );
    }

    final coordinateArraySample = coordinateArrayViewConstructor(
      Uint8List(0).buffer,
    );
    final coordinateArrayElementSizeInBytes =
        coordinateArraySample.elementSizeInBytes;
    final coordinateArrayType = coordinateArraySample.runtimeType;

    final coordinateArrayTypeIndex = _arrayTypes.indexOf(coordinateArrayType);
    if (coordinateArrayTypeIndex < 0) {
      throw ArgumentError(
        'Unexpected typed array class: $coordinateArrayType',
      );
    }

    // calculate the total number of nodes in the R-tree to allocate space for
    // and the index of each tree level (used in search later)
    var n = numItems;

    var numNodes = n;
    _levelBounds.add(n * 4);
    do {
      n = (n / nodeSize).ceil();
      numNodes += n;
      _levelBounds.add(numNodes * 4);
    } while (n != 1);

    indexArrayViewConstructor = (numNodes < 2 ^ 14
        ? Uint16List.view
        : Uint32List.view) as TypedArrayViewConstructor;
    final indexArrayElementSizeInBytes = indexArrayViewConstructor(
      Uint8List(0).buffer,
    ).elementSizeInBytes;

    final nodesByteSize = numNodes * 4 * coordinateArrayElementSizeInBytes;

    _data = Uint8List(
      8 + nodesByteSize + numNodes * indexArrayElementSizeInBytes,
    ).buffer;
    _boxes =
        coordinateArrayViewConstructor(_data, 8, numNodes * 4) as List<num>;
    _indices = indexArrayViewConstructor(_data, 8 + nodesByteSize, numNodes)
        as List<num>;
    _pos = 0;
    _indexMinX = double.infinity;
    _indexMinY = double.infinity;
    _indexMaxX = double.negativeInfinity;
    _indexMaxY = double.negativeInfinity;

    // set header information
    Uint8List.view(_data, 0, 2).setRange(0, 2, [
      0xfb,
      (_version << 4) + coordinateArrayTypeIndex,
    ]);
    Uint16List.view(_data, 2, 1)[0] = nodeSize;
    Uint32List.view(_data, 4, 1)[0] = numItems;
  }

  /// Allowed typed array types.
  static const List<Type> _arrayTypes = [
    Int8List,
    Uint8List,
    Uint8ClampedList,
    Int16List,
    Uint16List,
    Int32List,
    Uint32List,
    Float32List,
    Float64List,
  ];

  /// Serialized format version.
  static const int _version = 3;

  /// Default size of the tree node.
  static const int defaultNodeSize = 16;

  /// The number of items the index will hold.
  final int numItems;

  /// Size of the tree node of the index.
  final int nodeSize;

  /// The typed array constructor used for coordinate storage.
  final TypedArrayViewConstructor coordinateArrayViewConstructor;

  /// The typed array constructor used for index storage.
  late final TypedArrayViewConstructor indexArrayViewConstructor;

  late ByteBuffer _data;
  late List<num> _boxes;
  late List<num> _indices;
  List<int> _levelBounds = [];
  int _pos = 0;
  num _indexMinX = double.infinity;
  num _indexMinY = double.infinity;
  num _indexMaxX = double.negativeInfinity;
  num _indexMaxY = double.negativeInfinity;
  // List<int> _queue = [];

  /// Adds a given rectangle to the index, specified by
  /// [minX], [minY], [maxX], and [maxY], and returns
  /// the corresponding [ItemIdx] for the added item.
  ItemIdx add({
    required num minX,
    required num minY,
    required num maxX,
    required num maxY,
  }) {
    final index = _pos >> 2;
    _indices[index] = index;
    _boxes[_pos++] = minX;
    _boxes[_pos++] = minY;
    _boxes[_pos++] = maxX;
    _boxes[_pos++] = maxY;

    if (minX < _indexMinX) _indexMinX = minX;
    if (minY < _indexMinY) _indexMinY = minY;
    if (maxX > _indexMaxX) _indexMaxX = maxX;
    if (maxY > _indexMaxY) _indexMaxY = maxY;

    return index;
  }

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

/// Constructor for a typed array view of byte bufer
typedef TypedArrayViewConstructor = TypedData Function(
  ByteBuffer buffer, [
  int offsetInBytes,
  int? length,
]);

/// Constructor for data buffers
typedef DataBufferConstructor = TypedData Function(int length);
