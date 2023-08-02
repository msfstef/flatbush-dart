import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flatbush_dart/flatbush_dart.dart';
import 'package:flatbush_dart/src/geo_utils.dart';
import 'package:flatbush_dart/src/sorting_utils.dart';

/// Wrapper around [Flatbush] to provide geographical kNN search on the
/// index, using the [around] method which accounts for the curvature of the
/// earth.
class Geoflatbush {
  /// Creates a new [Geoflatbush] instance for a given [Flatbush] instance.
  /// The [Flatbush] instance requires a `double` [TypedData] type, e.g.
  /// [Float64List].
  const Geoflatbush(this._index);
  final Flatbush<TypedData, double> _index;

  /// Returns an array of item indices in order of distance for the
  /// given coordinates [lng] and [lat], accounting for the curvature
  /// of the earth and dateline wrapping.
  ///
  /// The [maxResults] parameter limits the number of results returned.
  /// If not set, then number of results is not limited.
  ///
  /// The [maxDistance] parameter limits the distance from the given
  /// coordinate to the results returned, with units of metres.
  /// If not set, then distance from given coordinate is not
  /// accounted for when filtering results.
  ///
  /// The [filter] parameter can be used to filter the results based
  /// on their [ItemIdx].
  ///
  /// This is the geographic equivalent of [Flatbush.neighbors].
  List<ItemIdx> around(
    double lng,
    double lat, {
    int? maxResults,
    double? maxDistance,
    FlatbushFilter? filter,
  }) {
    final result = <int>[];

    final latRad = GeoUtils.degToRad(lat);
    final cosLat = cos(latRad);
    final sinLat = sin(latRad);

    // a distance-sorted priority queue that will contain
    // both points and tree nodes
    final q = HeapPriorityQueue<(ItemIdx, double)>(
      (a, b) => a.$2.compareTo(b.$2),
    );

    // index of the top tree node (the whole Earth)
    var nodeIndex = _index.boxes.length - 4;

    while (true) {
      // find the end index of the node
      final end = min(
        nodeIndex + _index.nodeSize * 4,
        SortingUtils.upperBound(nodeIndex, _index.levelBounds),
      );

      // add child nodes to the queue
      for (var pos = nodeIndex; pos < end; pos += 4) {
        final childIndex = _index.indices[pos >> 2];

        final minLng = _index.boxes[pos];
        final minLat = _index.boxes[pos + 1];
        final maxLng = _index.boxes[pos + 2];
        final maxLat = _index.boxes[pos + 3];

        final dist = GeoUtils.greatCircleDistanceToBox(
          lng,
          lat,
          minLng,
          minLat,
          maxLng,
          maxLat,
          cosLat,
          sinLat,
        );

        if (nodeIndex < _index.numItems * 4) {
          // leaf node
          // put a negative index if it's an item rather
          // than a node, to recognize later
          if (filter?.call(childIndex) ?? true) {
            q.add((-childIndex - 1, dist));
          }
        } else {
          q.add((childIndex, dist));
        }
      }

      while (q.length > 0 && q.first.$1 < 0) {
        final dist = q.first.$2;
        if (maxDistance != null && dist > maxDistance) return result;
        result.add(-q.removeFirst().$1 - 1);
        if (result.length == maxResults) return result;
      }

      if (q.isEmpty) break;
      nodeIndex = q.removeFirst().$1;
    }

    return result;
  }
}
