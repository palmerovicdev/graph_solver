import 'dart:math';

final class SuperGraphAdjacency {
  SuperGraphAdjacency._();

  static const int defaultVertexCount = 100;

  static const double defaultDesiredDensity = 0.5;

  static String nodeId(int index) => 'v$index';

  static Map<String, Set<String>> build({
    int vertices = defaultVertexCount,
    double desiredDensity = defaultDesiredDensity,
    int? seed,
    Random? random,
  }) {
    if (vertices < 2) {
      throw ArgumentError.value(vertices, 'vertices', 'need at least 2');
    }
    if (desiredDensity <= 0 || desiredDensity > 1) {
      throw ArgumentError.value(
        desiredDensity,
        'desiredDensity',
        'must be in (0, 1].',
      );
    }

    final rng = random ?? (seed != null ? Random(seed) : Random());

    final adjacency = <String, Set<String>>{
      for (var i = 0; i < vertices; i++) nodeId(i): <String>{},
    };

    for (var i = 0; i < vertices; i++) {
      final a = nodeId(i);
      for (var j = i + 1; j < vertices; j++) {
        final u = rng.nextDouble();
        if (u < desiredDensity) {
          final b = nodeId(j);
          adjacency[a]!.add(b);
          adjacency[b]!.add(a);
        }
      }
    }

    return adjacency;
  }
}
