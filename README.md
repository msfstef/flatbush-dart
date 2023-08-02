# Flatbush Dart

A fast static spatial index for 2D points and rectangles in Dart, ported from the [excellent JavaScript implementation](https://github.com/mourner/flatbush/tree/main) by [Volodymyr Agafonkin](https://github.com/mourner), and includes [the extension for geographic queries](https://github.com/mourner/geoflatbush).


## Usage

```dart
// Initialize Flatbush for a given number type and number of items
final index = Flatbush.double64(1000);

// fill it with 1000 rectangles
for (final p in items) {
    index.add(
      minX: p.minX,
      minY: p.minY,
      maxX: p.maxX,
      maxY: p.maxY
    );
}

// perform the indexing
index.finish();

// make a bounding box query
final found = index.search(
  minX: minX,
  minY: minY,
  maxX: maxX,
  maxY: maxY
).map((i) => items[i]);
```