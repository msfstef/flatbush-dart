part of 'flatbush_dart.dart';

/// Static generators of [Flatbush] indices with given types
extension FlatbushGenerators on Flatbush {
  /// Creates a [Flatbush] instance with [Int8List] storage
  static Flatbush<Int8List, int> int8(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Int8List, int>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Uint8List] storage
  static Flatbush<Uint8List, int> uint8(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Uint8List, int>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Uint8ClampedList] storage
  static Flatbush<Uint8ClampedList, int> uint8Clamped(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Uint8ClampedList, int>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Int16List] storage
  static Flatbush<Int16List, int> int16(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Int16List, int>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Uint16List] storage
  static Flatbush<Uint16List, int> uint16(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Uint16List, int>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Int32List] storage
  static Flatbush<Int32List, int> int32(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Int32List, int>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Uint32List] storage
  static Flatbush<Uint32List, int> uint32(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Uint32List, int>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Float32List] storage
  static Flatbush<Float32List, double> double32(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Float32List, double>(
        numItems: numItems,
        nodeSize: nodeSize,
      );

  /// Creates a [Flatbush] instance with [Float64List] storage
  static Flatbush<Float64List, double> double64(
    int numItems, {
    int nodeSize = Flatbush.defaultNodeSize,
  }) =>
      Flatbush<Float64List, double>(
        numItems: numItems,
        nodeSize: nodeSize,
      );
}
