import 'dart:typed_data';

/// Collection of utilities to handle [TypedData] types
abstract class TypedArrayUtils {
  /// Creates a typed data view of type [arrayType] from the given [buffer],
  /// with given [offsetInBytes] and [length].
  static TypedData getTypedArrayView(
    Type arrayType,
    ByteBuffer buffer, [
    int offsetInBytes = 0,
    int? length,
  ]) {
    TypedData Function(ByteBuffer, [int, int?]) viewConstructor;
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

  /// Returns the size in bytes of a single element of the given
  /// typed data of type [arrayType].
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

  /// Returns the number type of the given [arrayType].
  /// e.g. a an [Int8List] has type [int], while a
  /// [Float32List] has type [double].
  static Type getTypedArrayElementType(Type arrayType) {
    switch (arrayType) {
      case Int8List:
      case Uint8List:
      case Uint8ClampedList:
      case Int16List:
      case Uint16List:
      case Int32List:
      case Uint32List:
        return int;
      case Float32List:
      case Float64List:
        return double;
      default:
        return num;
    }
  }

  /// Returns the minimum and maximum numbers that can be contained within
  /// an array of type [arrayType].
  static (num, num) getTypedArrayRange(Type arrayType) {
    switch (arrayType) {
      case Int8List:
        return (-128, 127);
      case Uint8List:
        return (0, 255);
      case Uint8ClampedList:
        return (0, 255);
      case Int16List:
        return (-32768, 32767);
      case Uint16List:
        return (0, 65535);
      case Int32List:
        return (-2147483648, 2147483647);
      case Uint32List:
        return (0, 4294967295);
      case Float32List:
        return (-3.4028234663852886e+38, 3.4028234663852886e+38);
      case Float64List:
        return (-1.7976931348623157e+308, 1.7976931348623157e+308);
      default:
        throw ArgumentError(
          'Invalid typed data type: $arrayType',
        );
    }
  }
}
