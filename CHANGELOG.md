### 1.2.2
* Loosen dependency requirements - Flutter SDK still behind.
### 1.2.1
* Removed testing in Chrome VM as cities DB for testing `Geoflatbush` is incompatible - library still works but will have to come back to fix testing.
### 1.2.0
* Added `Geoflatbush` wrapper to `Flatbush` to allow curvature and dateline aware kNN queries with the `around` API.
### 1.1.0
* Added `neighbors` API for kNN search on index using Dart's collection HeapPriorityQueue.
### 1.0.2
* Slightly refactored files to follow Dart package conventions
### 1.0.1
* Added repository to pubspec.yaml
* Added GitHub Actions workflows for testing and deployment

### 1.0.0
* Implemented basic APIs except kNN search.

### 0.0.1
* Set up flutter package (linting, license, etc)
