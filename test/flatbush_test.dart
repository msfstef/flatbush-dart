import 'dart:typed_data';

import 'package:flatbush_dart/flatbush_dart.dart';
import 'package:test/test.dart';

import 'sample_data.dart';

void main() {
  group('Flatbush', () {
    const data = sampleData;

    Flatbush<Float64List, double> createIndex() {
      final index = Flatbush.double64(data.length ~/ 4);
      for (var i = 0; i < data.length; i += 4) {
        index.add(
          minX: data[i],
          minY: data[i + 1],
          maxX: data[i + 2],
          maxY: data[i + 3],
        );
      }
      index.finish();
      return index;
    }

    Flatbush<Float64List, double> createSmallIndex(int numItems, int nodeSize) {
      final index = Flatbush.double64(numItems, nodeSize: nodeSize);
      for (var i = 0; i < 4 * numItems; i += 4) {
        index.add(
          minX: data[i],
          minY: data[i + 1],
          maxX: data[i + 2],
          maxY: data[i + 3],
        );
      }
      index.finish();
      return index;
    }

    Flatbush<Int32List, int> createIntIndex() {
      final index = Flatbush.int32(data.length ~/ 4);
      for (var i = 0; i < data.length; i += 4) {
        index.add(
          minX: data[i].toInt(),
          minY: data[i + 1].toInt(),
          maxX: data[i + 2].toInt(),
          maxY: data[i + 3].toInt(),
        );
      }
      index.finish();
      return index;
    }

    test('indexes a bunch of rectangles', () {
      final index = createIndex();

      expect(
        index.boxes.length + index.indices.length,
        equals(540),
      );
      expect(
        index.boxes.sublist(index.boxes.length - 4, index.boxes.length),
        equals([0, 1, 96, 95]),
      );
      expect(
        index.indices[index.boxes.length ~/ 4 - 1],
        equals(400),
      );
    });

    test('skips sorting less than nodeSize number of rectangles', () {
      const numItems = 14;
      const nodeSize = 16;
      final index = createSmallIndex(numItems, nodeSize);

      // Compute expected root box extents
      num rootXMin = double.infinity;
      num rootYMin = double.infinity;
      num rootXMax = double.negativeInfinity;
      num rootYMax = double.negativeInfinity;
      for (var i = 0; i < 4 * numItems; i += 4) {
        if (data[i] < rootXMin) rootXMin = data[i];
        if (data[i + 1] < rootYMin) rootYMin = data[i + 1];
        if (data[i + 2] > rootXMax) rootXMax = data[i + 2];
        if (data[i + 3] > rootYMax) rootYMax = data[i + 3];
      }

      // Sort should be skipped, ordered progressing indices expected
      final expectedIndices = List<int>.generate(numItems, (i) => i)..add(0);

      expect(
        index.indices,
        equals(expectedIndices),
      );
      expect(
        index.boxes.length,
        equals((numItems + 1) * 4),
      );
      expect(
        index.boxes.sublist(index.boxes.length - 4, index.boxes.length),
        equals([rootXMin, rootYMin, rootXMax, rootYMax]),
      );
    });

    test('performs bbox search', () {
      final index = createIndex();

      final ids = index.search(
        minX: 40,
        minY: 40,
        maxX: 60,
        maxY: 60,
      );

      final results = <num>[];
      for (var i = 0; i < ids.length; i++) {
        results.addAll([
          data[4 * ids[i]],
          data[4 * ids[i] + 1],
          data[4 * ids[i] + 2],
          data[4 * ids[i] + 3],
        ]);
      }

      expect(
        results..sort(),
        equals(
          [57, 59, 58, 59, 48, 53, 52, 56, 40, 42, 43, 43, 43, 41, 47, 43]
            ..sort(),
        ),
      );
    });

    test('performs bbox search on integers', () {
      final index = createIntIndex();

      final ids = index.search(
        minX: 40,
        minY: 40,
        maxX: 60,
        maxY: 60,
      );

      final results = <num>[];
      for (var i = 0; i < ids.length; i++) {
        results.addAll([
          data[4 * ids[i]],
          data[4 * ids[i] + 1],
          data[4 * ids[i] + 2],
          data[4 * ids[i] + 3],
        ]);
      }

      expect(
        results..sort(),
        equals(
          [57, 59, 58, 59, 48, 53, 52, 56, 40, 42, 43, 43, 43, 41, 47, 43]
            ..sort(),
        ),
      );
    });

    test('reconstructs an index from array buffer', () {
      final index = createIndex();

      final index2 = Flatbush.from(index.data);

      expect(index2, equals(index));

      expect(
        index.boxes.length + index.indices.length,
        index2.boxes.length + index2.indices.length,
      );
      expect(
        index.boxes.sublist(index.boxes.length - 4, index.boxes.length),
        index2.boxes.sublist(index2.boxes.length - 4, index2.boxes.length),
      );
      expect(
        index.indices[index.boxes.length ~/ 4 - 1],
        index2.indices[index2.boxes.length ~/ 4 - 1],
      );
    });

    test('throws an error if added less items than the index size', () {
      expect(
        () => Flatbush.double64(data.length ~/ 4).finish(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws an error if searching before indexing', () {
      expect(
        () => Flatbush.double64(data.length ~/ 4)
            .search(minX: 0, minY: 0, maxX: 20, maxY: 20),
        throwsA(isA<Exception>()),
      );
    });

    test('does not freeze on numItems = 0', () {
      expect(() => Flatbush.double64(0), throwsA(isA<ArgumentError>()));
    });

    test('performs a k-nearest-neighbors query', () {
      final index = createIndex();
      final ids = index.neighbors(50, 50, maxResults: 3);

      expect(ids..sort(), equals([31, 6, 75]..sort()));
    });

    test('k-nearest-neighbors query accepts maxDistance', () {
      final index = createIndex();
      final ids = index.neighbors(
        50,
        50,
        maxDistance: 12,
      );

      expect(ids..sort(), equals([6, 29, 31, 75, 85]..sort()));
    });

    test('k-nearest-neighbors query accepts filterFn', () {
      final index = createIndex();
      final ids = index.neighbors(
        50,
        50,
        maxResults: 6,
        maxDistance: double.infinity,
        filter: (int i) => i.isEven,
      );

      expect(ids..sort(), equals([6, 16, 18, 24, 54, 80]..sort()));
    });

    test('performs a k-nearest-neighbors query with all items', () {
      final index = createIndex();
      final ids = index.neighbors(50, 50);

      expect(ids.length, equals(data.length >> 2));
    });

    test('returns index of newly-added rectangle', () {
      const count = 5;
      final index = Flatbush.double64(count);

      final ids = <int>[];
      for (var i = 0; i < count; i++) {
        final id = index.add(
          minX: data[i],
          minY: data[i + 1],
          maxX: data[i + 2],
          maxY: data[i + 3],
        );
        ids.add(id);
      }

      final expectedSequence = List.generate(count, (i) => i);
      expect(ids, equals(expectedSequence));
    });
  });
}
