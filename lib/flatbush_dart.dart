import 'dart:math';
import 'dart:typed_data';

import 'package:flatbush_dart/utils.dart';
import 'package:meta/meta.dart';

/// Fast spatial index for 2D points and rectangles.
class Flatbush {
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
    this.bufferConstructor = defaultBufferConstructor,
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

    _data = bufferConstructor(
      8 + nodesByteSize + numNodes * indexArrayElementSizeInBytes,
    );
    _boxes =
        coordinateArrayViewConstructor(_data, 8, numNodes * 4) as List<num>;
    _indices = indexArrayViewConstructor(_data, 8 + nodesByteSize, numNodes)
        as List<int>;
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

  /// Default byte buffer constructor, using [Uint8List] typed
  /// array to generate a buffer.
  static ByteBuffer defaultBufferConstructor(int length) =>
      Uint8List(length).buffer;

  /// Default size of the tree node.
  static const int defaultNodeSize = 16;

  /// The number of items the index will hold.
  final int numItems;

  /// Size of the tree node of the index.
  final int nodeSize;

  /// The typed array constructor used for coordinate storage.
  final TypedArrayViewConstructor coordinateArrayViewConstructor;

  /// The byte buffer constructor used to store the whole index.
  final DataBufferConstructor bufferConstructor;

  /// The typed array constructor used for item index storage.
  late final TypedArrayViewConstructor indexArrayViewConstructor;

  late ByteBuffer _data;
  late List<num> _boxes;

  /// TESTING ONLY
  /// The bounding boxes added to the index
  @visibleForTesting
  List<num> get boxes => _boxes;

  late List<int> _indices;

  /// TESTING ONLY
  /// The indices of the items in the index
  @visibleForTesting
  List<num> get indices => _indices;

  final List<int> _levelBounds = [];
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
  void finish() {
    if (_pos >> 2 != numItems) {
      throw Exception('Added ${_pos >> 2} items when expected $numItems.');
    }

    final boxes = _boxes;

    if (numItems <= nodeSize) {
      // only one node, skip sorting and just fill the root box
      boxes[_pos++] = _indexMinX;
      boxes[_pos++] = _indexMinY;
      boxes[_pos++] = _indexMaxX;
      boxes[_pos++] = _indexMaxY;
      return;
    }

    final width = _indexMaxX > _indexMinX ? _indexMaxX - _indexMinX : 1;
    final height = _indexMaxY > _indexMinY ? _indexMaxY - _indexMinY : 1;
    final hilbertValues = Uint32List(numItems);
    const hilbertMax = (1 << 16) - 1;

    // map item centers into Hilbert coordinate space
    // and calculate Hilbert values
    for (var i = 0, pos = 0; i < numItems; i++) {
      final minX = boxes[pos++];
      final minY = boxes[pos++];
      final maxX = boxes[pos++];
      final maxY = boxes[pos++];
      final x = (hilbertMax * ((minX + maxX) / 2 - _indexMinX) / width).floor();
      final y =
          (hilbertMax * ((minY + maxY) / 2 - _indexMinY) / height).floor();
      hilbertValues[i] = hilbert(x, y);
    }

    // sort items by their Hilbert value (for packing later)
    sort(hilbertValues, boxes, _indices, 0, numItems - 1, nodeSize);

    // generate nodes at each tree level, bottom-up
    for (var i = 0, pos = 0; i < _levelBounds.length - 1; i++) {
      final end = _levelBounds[i];

      // generate a parent node for each block of consecutive [nodeSize] nodes
      while (pos < end) {
        final nodeIndex = pos;

        // calculate bbox for the new node
        var nodeMinX = boxes[pos++];
        var nodeMinY = boxes[pos++];
        var nodeMaxX = boxes[pos++];
        var nodeMaxY = boxes[pos++];
        for (var j = 1; j < nodeSize && pos < end; j++) {
          nodeMinX = min(nodeMinX, boxes[pos++]);
          nodeMinY = min(nodeMinY, boxes[pos++]);
          nodeMaxX = max(nodeMaxX, boxes[pos++]);
          nodeMaxY = max(nodeMaxY, boxes[pos++]);
        }

        // add the new node to the tree data
        _indices[_pos >> 2] = nodeIndex;
        boxes[_pos++] = nodeMinX;
        boxes[_pos++] = nodeMinY;
        boxes[_pos++] = nodeMaxX;
        boxes[_pos++] = nodeMaxY;
      }
    }
  }

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
  }) {
    if (_pos != _boxes.length) {
      throw Exception('Data not yet indexed - call index.finish().');
    }

    int? nodeIndex = _boxes.length - 4;
    final queue = <int>[];
    final results = <int>[];

    while (nodeIndex != null) {
      // find the end index of the node
      final end = min(
        nodeIndex + nodeSize * 4,
        upperBound(
          nodeIndex,
          _levelBounds,
        ),
      );

      // search through child nodes
      for (var pos = nodeIndex; pos < end; pos += 4) {
        // check if node bbox intersects with query bbox
        if (maxX < _boxes[pos]) continue; // maxX < nodeMinX
        if (maxY < _boxes[pos + 1]) continue; // maxY < nodeMinY
        if (minX > _boxes[pos + 2]) continue; // minX > nodeMaxX
        if (minY > _boxes[pos + 3]) continue; // minY > nodeMaxY

        final index = _indices[pos >> 2];

        if (nodeIndex >= numItems * 4) {
          // node; add it to the search queue
          queue.add(index);
        } else if (filter?.call(index) ?? true) {
          // leaf item
          results.add(index);
        }
      }

      if (queue.isNotEmpty) {
        nodeIndex = queue.removeLast();
      } else {
        nodeIndex = null;
      }
    }

    return results;
  }

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
  }) {
    // TODO: implement FlatQueue to perform kNN search
    throw UnimplementedError('Must implement FlatQueue first');
  }
}

/// The index of an item as returned by [Flatbush.add]
/// when the item is added to the index.
typedef ItemIdx = int;

/// A function that filters the results of a search
/// based on the [index] of the item.
typedef FlatbushFilter = bool Function(ItemIdx index);

/// Constructor for a typed array view of byte bufer [buffer],
/// with given [offsetInBytes] and [length].
typedef TypedArrayViewConstructor = TypedData Function(
  ByteBuffer buffer, [
  int offsetInBytes,
  int? length,
]);

/// Constructor for a byte buffer of given [length].
typedef DataBufferConstructor = ByteBuffer Function(int length);
