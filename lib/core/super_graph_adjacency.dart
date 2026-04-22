import 'dart:math';

/// Random undirected simple graphs on `v0` … `v{n-1}`.
///
/// Generation follows the usual **uniform edge** rule: for each possible
/// (unordered) edge, draw one number from a **uniform distribution on [0, 1)**;
/// if it is **strictly less than** [desiredDensity], that edge is included.
/// So [desiredDensity] is the per-edge inclusion probability (graph density
/// parameter in the Erdős–Rényi `G(n, p)` sense with `p = desiredDensity`).
///
/// [Random.nextDouble] in Dart is uniform on `[0.0, 1.0)` (1.0 is not returned),
/// so `desiredDensity == 1.0` yields the complete graph `K_n`.
final class SuperGraphAdjacency {
  SuperGraphAdjacency._();

  static const int defaultVertexCount = 1000;

  /// Default per-edge inclusion probability.
  static const double defaultDesiredDensity = 0.5;

  static String nodeId(int index) => 'v$index';

  /// Builds an undirected adjacency map (symmetric sets; every vertex is a key).
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
