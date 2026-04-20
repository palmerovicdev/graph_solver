class ColorateWithBacktracking<T> {
  const ColorateWithBacktracking();

  Map<T, int> call(
    Map<T, Set<T>> adjacency, {
    List<T>? visitOrder,
    int? maxColors,
  }) {
    if (maxColors != null && maxColors < 1) {
      throw ArgumentError.value(
        maxColors,
        'maxColors',
        'must be greater than 0.',
      );
    }

    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      return <T, int>{};
    }

    final order = _buildVisitOrder(normalized, visitOrder);
    final colorByNode = <T, int>{};
    final upperBound = maxColors ?? normalized.length;

    for (var colorCount = 1; colorCount <= upperBound; colorCount++) {
      colorByNode.clear();
      final solved = _search(
        nodeIndex: 0,
        order: order,
        adjacency: normalized,
        colorByNode: colorByNode,
        colorCount: colorCount,
      );
      if (solved) {
        return Map<T, int>.from(colorByNode);
      }
    }

    if (maxColors != null) {
      throw StateError('No valid coloring found with maxColors=$maxColors.');
    }

    // This should be unreachable because any graph can be colored with N colors.
    throw StateError('No valid coloring found.');
  }

  bool _search({
    required int nodeIndex,
    required List<T> order,
    required Map<T, Set<T>> adjacency,
    required Map<T, int> colorByNode,
    required int colorCount,
  }) {
    if (nodeIndex >= order.length) {
      return true;
    }

    final node = order[nodeIndex];

    for (var color = 0; color < colorCount; color++) {
      if (!_canUseColor(node, color, adjacency, colorByNode)) {
        continue;
      }

      colorByNode[node] = color;

      if (_search(
        nodeIndex: nodeIndex + 1,
        order: order,
        adjacency: adjacency,
        colorByNode: colorByNode,
        colorCount: colorCount,
      )) {
        return true;
      }

      colorByNode.remove(node);
    }

    return false;
  }

  bool _canUseColor(
    T node,
    int color,
    Map<T, Set<T>> adjacency,
    Map<T, int> colorByNode,
  ) {
    for (final neighbor in adjacency[node] ?? <T>{}) {
      if (colorByNode[neighbor] == color) {
        return false;
      }
    }
    return true;
  }

  List<T> _buildVisitOrder(Map<T, Set<T>> adjacency, List<T>? customOrder) {
    final order = <T>[];
    final seen = <T>{};

    if (customOrder != null) {
      for (final node in customOrder) {
        if (!adjacency.containsKey(node)) {
          continue;
        }
        if (seen.add(node)) {
          order.add(node);
        }
      }
    }

    final remaining =
        adjacency.keys.where((node) => !seen.contains(node)).toList()
          ..sort((a, b) {
            final degreeComparison = adjacency[b]!.length.compareTo(
              adjacency[a]!.length,
            );
            if (degreeComparison != 0) {
              return degreeComparison;
            }
            return a.toString().compareTo(b.toString());
          });

    order.addAll(remaining);
    return order;
  }

  /// Normalize undirected adjacency graph to ensure all nodes are connected.
  Map<T, Set<T>> _normalizeUndirectedAdjacency(Map<T, Set<T>> adjacency) {
    final normalized = <T, Set<T>>{};

    for (final entry in adjacency.entries) {
      normalized.putIfAbsent(entry.key, () => <T>{});
      for (final neighbor in entry.value) {
        if (neighbor == entry.key) {
          continue;
        }
        normalized.putIfAbsent(neighbor, () => <T>{});
        normalized[entry.key]!.add(neighbor);
        normalized[neighbor]!.add(entry.key);
      }
    }

    return normalized;
  }
}
