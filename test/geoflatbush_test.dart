import 'package:cities/cities.dart';
import 'package:flatbush_dart/flatbush_dart.dart';
import 'package:flatbush_dart/src/geo_utils.dart';
import 'package:test/test.dart';

void main() async {
  final cities = (await cities_auto()).all;
  group('Geoflatbush', () {
    final flatbushIndex = Flatbush.double64(cities.length, nodeSize: 4);

    for (final city in cities) {
      flatbushIndex.add(
        minX: city.longitude,
        minY: city.latitude,
        maxX: city.longitude,
        maxY: city.latitude,
      );
    }
    flatbushIndex.finish();
    final index = Geoflatbush(flatbushIndex);

    test('performs search according to maxResults', () {
      final points = index.around(-119.7051, 34.4363, maxResults: 5);
      expect(points.map((i) => cities[i].city.toLowerCase()), [
        'mission canyon',
        'santa barbara',
        'irma',
        'el sueno',
        'hope ranch',
      ]);
    });

    test('performs search within maxDistance', () {
      final points = index.around(20.718675, 39.251388, maxDistance: 3000);
      expect(
        points.map((i) => cities[i].city.toLowerCase()),
        [
          'zermi',
          'vrysoula',
          'vrisoula',
          'kranea',
          'krania',
          'ano kotsanopoulo',
          'ano kotsanopoulon'
        ],
      );
    });

    test('performs search using filter function', () {
      final points = index.around(
        20.718675,
        39.251388,
        maxResults: 1,
        filter: (i) => cities[i].city.toLowerCase().startsWith('krania'),
      );
      expect(
        points.map((i) => cities[i].city.toLowerCase()),
        [
          'krania',
        ],
      );
    });

    test('performs exhaustive search in correct order', () {
      final lngLat = [30.5, 50.5];
      final citiesFound = index
          .around(
            lngLat[0],
            lngLat[1],
          )
          .map((i) => cities[i])
          .toList();

      final sorted = cities
          .map(
            (city) => {
              'item': city,
              'dist': GeoUtils.distance(
                lngLat[0],
                lngLat[1],
                city.longitude,
                city.latitude,
              )
            },
          )
          .toList()
        ..sort((a, b) => (a['dist']! as num).compareTo(b['dist']! as num));

      for (var i = 0; i < sorted.length; i++) {
        final dist = GeoUtils.distance(
          citiesFound[i].longitude,
          citiesFound[i].latitude,
          lngLat[0],
          lngLat[1],
        );
        expect(dist, sorted[i]['dist']);
      }
    });

    test('calculates great circle distance', () {
      expect(
        GeoUtils.distance(30.5, 50.5, -119.7, 34.4).round(),
        10131740,
      );
    });
  });
}
