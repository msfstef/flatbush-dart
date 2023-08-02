import 'dart:math';

/// Set of utilities for handling geographic data.
abstract class GeoUtils {
  static const double _earthRadius = 6371000;
  static const double _earthCircumference = 2 * pi * _earthRadius;
  static const double _degToRad = pi / 180.0;

  /// Converts degrees to radians.
  static double degToRad(double deg) => deg * _degToRad;

  /// Calculates the great-circle distance between a point with coordinate
  /// ([lng], [lat]) and a bounding box defined by
  /// ([minLng], [minLat], [maxLng], [maxLat]), given the cosine and sine of
  /// the point's latitude [cosLat] and [sinLat].
  static double greatCircleDistanceToBox(
    double lng,
    double lat,
    double minLng,
    double minLat,
    double maxLng,
    double maxLat,
    double cosLat,
    double sinLat,
  ) {
    // if box is point, distance is just between two points
    if (minLng == maxLng && minLat == maxLat) {
      return greatCircleDistance(lng, lat, minLng, minLat, cosLat, sinLat);
    }

    // query point is between minimum and maximum longitudes
    if (lng >= minLng && lng <= maxLng) {
      // south
      if (lat <= minLat) {
        return _earthCircumference * (minLat - lat) / 360;
      }

      // north
      if (lat >= maxLat) {
        return _earthCircumference * (lat - maxLat) / 360;
      }

      // inside the bbox
      return 0;
    }

    // query point is west or east of the bounding box;
    // calculate the extremum for great circle distance from
    // query point to the closest longitude
    final closestLng = (minLng - lng + 360) % 360 <= (lng - maxLng + 360) % 360
        ? minLng
        : maxLng;
    final cosLngDelta = cos((closestLng - lng) * _degToRad);
    final extremumLat = atan(sinLat / (cosLat * cosLngDelta)) / _degToRad;

    // calculate distances to lower and higher bbox
    // corners and extremum (if it's within this range);
    // one of the three distances will be the lower bound
    // of great circle distance to bbox
    double d = max(
      _greatCircleDistancePart(minLat, cosLat, sinLat, cosLngDelta),
      _greatCircleDistancePart(maxLat, cosLat, sinLat, cosLngDelta),
    );

    if (extremumLat > minLat && extremumLat < maxLat) {
      d = max(
        d,
        _greatCircleDistancePart(
          extremumLat,
          cosLat,
          sinLat,
          cosLngDelta,
        ),
      );
    }

    return _earthRadius * acos(d);
  }

  /// Calculates the great circle distance in metres between two coordnates
  /// ([lng], [lat]) amd ([lng2], [lat2]) for the given cosine and sine of
  /// the latitude [cosLat] and [sinLat].
  static double greatCircleDistance(
    double lng,
    double lat,
    double lng2,
    double lat2,
    double cosLat,
    double sinLat,
  ) {
    final cosLngDelta = cos((lng2 - lng) * _degToRad);
    return _earthRadius *
        acos(
          _greatCircleDistancePart(
            lat2,
            cosLat,
            sinLat,
            cosLngDelta,
          ),
        );
  }

  static double _greatCircleDistancePart(
    double lat,
    double cosLat,
    double sinLat,
    double cosLngDelta,
  ) {
    final d = sinLat * sin(lat * _degToRad) +
        cosLat * cos(lat * _degToRad) * cosLngDelta;
    return min(d, 1);
  }

  /// Calculates the great circle distance in metres between two points
  /// with coordinates ([lng], [lat]) and ([lng2], [lat2]).
  static double distance(double lng, double lat, double lng2, double lat2) {
    return greatCircleDistance(
      lng,
      lat,
      lng2,
      lat2,
      cos(lat * _degToRad),
      sin(lat * _degToRad),
    );
  }
}
