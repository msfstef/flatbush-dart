import 'dart:typed_data';

/// Collection of utilities to handle [TypedData] types
abstract class TypedArrayUtils {
  /// Returns the index of the given typed data type [arrayType] in
  /// [arrayTypes].
  static int getTypedArrayIndex(Type arrayType, List<Type> arrayTypes) {
    final index = arrayTypes.indexOf(arrayType);
    if (index == -1) {
      throw ArgumentError('Invalid typed data type: $arrayType');
    }
    return index;
  }

  /// Creates a typed data view of type [T] from the given [buffer],
  /// with given [offsetInBytes] and [length].
  static TypedData getTypedArrayView(
    Type arrayType,
    ByteBuffer buffer, [
    int offsetInBytes = 0,
    int? length,
  ]) {
    TypedArrayViewConstructor viewConstructor;
    switch (arrayType) {
      case Int8List:
        viewConstructor = Int8List.view;
      case Uint8List:
        viewConstructor = Uint8List.view;
      case Uint8ClampedList:
        viewConstructor = Uint8ClampedList.view;
      case Int16List:
        viewConstructor = Int16List.view;
      case Uint16List:
        viewConstructor = Uint16List.view;
      case Int32List:
        viewConstructor = Int32List.view;
      case Uint32List:
        viewConstructor = Uint32List.view;
      case Float32List:
        viewConstructor = Float32List.view;
      case Float64List:
        viewConstructor = Float64List.view;
      default:
        throw ArgumentError(
          'Invalid typed data type: $arrayType',
        );
    }
    return viewConstructor(buffer, offsetInBytes, length);
  }

  /// Returns the size in bytes of a single element of the given typed data [T].
  static int getTypedArrayElementSizeInBytes(Type arrayType) {
    switch (arrayType) {
      case Int8List:
        return Int8List.bytesPerElement;
      case Uint8List:
        return Uint8List.bytesPerElement;
      case Uint8ClampedList:
        return Uint8ClampedList.bytesPerElement;
      case Int16List:
        return Int16List.bytesPerElement;
      case Uint16List:
        return Uint16List.bytesPerElement;
      case Int32List:
        return Int32List.bytesPerElement;
      case Uint32List:
        return Uint32List.bytesPerElement;
      case Float32List:
        return Float32List.bytesPerElement;
      case Float64List:
        return Float64List.bytesPerElement;
      default:
        throw ArgumentError(
          'Invalid typed data type: $arrayType',
        );
    }
  }
}

/// Constructor for a typed array view of byte bufer [buffer],
/// with given [offsetInBytes] and [length].
typedef TypedArrayViewConstructor = TypedData Function(
  ByteBuffer buffer, [
  int offsetInBytes,
  int? length,
]);
